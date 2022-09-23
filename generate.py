from collections import Counter
from functools import cache
from math import ceil, floor
from typing import Literal, Optional, TypedDict, Union
import requests
import re

API_DUMP_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json"
API_DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua"

# INCLUDE: Controls which classes and their descendants are included in froactful's generation.
# Including everything can cause luau-lsp to stop recognizing types properly.
INCLUDE = ["UIBase", "GuiBase2d", "BasePart", "Camera"]
# These clasess break luau-lsp, so they're excluded
EXCLUDE = [
    "Player",
    "Team",
    "RemoteFunction",
    "BinaryStringValue",
    "RemoteEvent",
    "ProximityPrompt",
    "ProximityPromptService",
]
# Whether froactful tries to simplify types by unioning super class types.
# luau doesn't properly infer parameters to signals when they're not completely inlined.
INLINE_INHERITED_PROPERTIES = False
INLINE_INHERITED_CALLBACKS = False
INLINE_ENTIRE_TYPE = False
INLINE_CALLBACKS = False

# Type defintions taken from https://github.com/JohnnyMorganz/luau-lsp/blob/main/scripts/dumpRobloxTypes.py
CorrectionsValueType = TypedDict(
    "CorrectionsValueType",
    {
        "Name": str,
        "Category": None,
        "Default": Optional[str],
    },
)

ApiValueType = TypedDict(
    "ApiValueType",
    {
        "Name": str,
        "Category": Literal["Primitive", "Class", "DataType", "Enum", "Group"],
    },
)

ApiParameter = TypedDict(
    "ApiParameter",
    {
        "Name": str,
        "Type": ApiValueType,
        "Default": Optional[str],
    },
)

ApiProperty = TypedDict(
    "ApiProperty",
    {
        "Name": str,
        "MemberType": Literal["Property"],
        "Description": Optional[str],
        "Tags": Optional[list[str]],
        "Category": str,
        "ValueType": ApiValueType,
    },
)

ApiFunction = TypedDict(
    "ApiFunction",
    {
        "Name": str,
        "MemberType": Literal["Function"],
        "Description": Optional[str],
        "Parameters": list[ApiParameter],
        "ReturnType": ApiValueType,
        "TupleReturns": Optional[CorrectionsValueType],
        "Tags": Optional[list[str]],
    },
)

ApiEvent = TypedDict(
    "ApiEvent",
    {
        "Name": str,
        "MemberType": Literal["Event"],
        "Description": Optional[str],
        "Parameters": list[ApiParameter],
        "Tags": Optional[list[str]],
    },
)

ApiCallback = TypedDict(
    "ApiCallback",
    {
        "Name": str,
        "MemberType": Literal["Callback"],
        "Description": Optional[str],
        "Parameters": list[ApiParameter],
        "ReturnType": ApiValueType,
        "TupleReturns": Optional[CorrectionsValueType],
        "Tags": Optional[list[str]],
    },
)

ApiMember = Union[ApiProperty, ApiFunction, ApiEvent, ApiCallback]

ApiClass = TypedDict(
    "ApiClass",
    {
        "Name": str,
        "Description": Optional[str],
        "MemoryCategory": str,
        "Superclass": str,
        "Members": list[ApiMember],
        "Tags": Optional[list[str]],
    },
)

ApiEnumItem = TypedDict(
    "ApiEnumItem",
    {
        "Name": str,
        "Value": int,
        "Description": Optional[str],
    },
)

ApiEnum = TypedDict(
    "ApiEnum",
    {
        "Name": str,
        "Description": Optional[str],
        "Items": list[ApiEnumItem],
    },
)

ApiDump = TypedDict(
    "ApiDump",
    {
        "Version": int,
        "Classes": list[ApiClass],
        "Enums": list[ApiEnum],
    },
)

dump: ApiDump = requests.get(API_DUMP_URL).json()
roblox_types = requests.get(API_DEFINITIONS_URL).text

with open("froact.lua") as fio:
    content = fio.read()


def property_type_definition(type_def: str):
    if type_def == "Content":
        return "string"
    elif type_def.startswith("Enum"):
        return "Enum." + type_def.removeprefix("Enum")
    elif type_def in ("Team", "Player"):
        return "any"
    else:
        return type_def


# self_type is either class name or Rbx
def signal_type_defintion(type_def: str, self_type: str):
    if match := (
        re.match(r"RBXScriptSignal\<\((.*)\)\>", type_def)
        or re.match(r"RBXScriptSignal\<(.*)\>", type_def)
    ):
        args = tuple(
            property_type_definition(x)
            for x in filter(None, match.group(1).split(", "))
        )
        args_def = ", ".join((self_type,) + args)
        if INLINE_CALLBACKS:
            return f"(rbx: {args_def}) -> ()?"
        else:
            return f"Event<{args_def}>?"
    else:
        raise Exception("Couldn't match signal definition " + type_def)


def bind_prop_type_definition(self_type: str):
    if INLINE_CALLBACKS:
        return f"(rbx: {self_type}) -> ()?"
    else:
        return f"BindProperty<{self_type}>?"


def is_bindable(property_name: str, klass: str):
    return (
        property_name.startswith("Absolute")
        or property_name == "TextBounds"
        or (klass == "TextBox" and property_name == "Text")
    )


ignored_types = ["ProtectedString", "Hole"]


reference_count: Counter[str] = Counter()


@cache
def lookup_class_def(klass: str):
    if match := re.search(
        rf"declare class {klass} extends (\w+)\n((?:.+\n)*)end", roblox_types
    ):
        super_class = match.group(1)
        fields_body = match.group(2)
    elif match := re.search(rf"declare class {klass}\n((?:.+\n)*)end", roblox_types):
        super_class = None
        fields_body = match.group(1)
    else:
        super_class = None
        fields_body = None
    return super_class, fields_body


def make_optional(type_def: str):
    return type_def if type_def[-1:] == "?" else type_def + "?"


@cache
def get_parsed_class_fields(klass: str):
    _, fields_body = lookup_class_def(klass)
    if fields_body is None:
        return {}
    return tuple(
        tuple(s.lstrip().split(": ", 1))
        for s in fields_body.splitlines()
        if not s.lstrip().startswith("function")
    )


@cache
def get_class_property_fields(klass: str):
    fields = get_parsed_class_fields(klass)
    property_fields = {f for f in fields if not f[1].startswith("RBXScriptSignal")}
    return tuple(
        (name, make_optional(property_type_definition(type_def)))
        for (name, type_def) in property_fields
        if type_def not in ignored_types
    )


@cache
def get_filtered_class_property_fields(klass: str):
    return tuple(
        (name, type_def)
        for (name, type_def) in get_class_property_fields(klass)
        if filter_class_field(klass, name)
    )


@cache
def get_class_signal_fields(klass: str, self_type):
    fields = get_parsed_class_fields(klass)
    signal_fields = {f for f in fields if f[1].startswith("RBXScriptSignal")}
    return tuple(
        ("on" + name, signal_type_defintion(type_def, self_type))
        for (name, type_def) in signal_fields
    )


@cache
def get_class_bind_fields(klass: str, self_type: str):
    property_fields = get_class_property_fields(klass)
    return tuple(
        ("bind" + name, bind_prop_type_definition(self_type))
        for (name, _) in property_fields
        if is_bindable(name, klass)
    )


@cache
def get_class_fields(klass: str, self_type: str):
    return get_filtered_class_property_fields(klass) + get_class_signal_fields(
        klass, self_type
    )


def parse_security(security):
    if security == "None":
        return True
    elif security == "PluginSecurity":
        return False
    elif security == "RobloxScriptSecurity":
        return False
    elif security == "LocalUserSecurity":
        return False
    else:
        return security["Write"] == "None"


def filter_class_field(klass_name, field_name):
    klass = next(klass for klass in dump["Classes"] if klass_name == klass["Name"])
    member = next(
        (member for member in klass["Members"] if member["Name"] == field_name), None
    )
    return (
        "ReadOnly" not in member.get("Tags", []) and parse_security(member["Security"])
        if member
        else False
    )


@cache
def get_parsed_class_fields_recursive(klass_name: str):
    super_class, _ = lookup_class_def(klass_name)
    fields = get_parsed_class_fields(klass_name)
    if super_class:
        fields += get_parsed_class_fields_recursive(super_class)
    return fields


@cache
def get_class_property_fields_recursive(klass_name: str):
    super_class, _ = lookup_class_def(klass_name)
    fields = get_filtered_class_property_fields(klass_name)
    if super_class:
        fields += get_class_property_fields_recursive(super_class)
    return fields


@cache
def get_class_signal_fields_recursive(klass_name: str, self_type: str):
    super_class, _ = lookup_class_def(klass_name)
    fields = get_class_signal_fields(klass_name, self_type)
    if super_class:
        fields += get_class_signal_fields_recursive(super_class, self_type)
    return fields


@cache
def get_class_bind_fields_recursive(klass_name: str, self_type: str):
    super_class, _ = lookup_class_def(klass_name)
    fields = get_class_bind_fields(klass_name, self_type)
    if super_class:
        fields += get_class_bind_fields_recursive(super_class, self_type)
    return fields


@cache
def has_ancestor(klass, ancestor):
    if klass == ancestor:
        return True
    elif super_class := lookup_class_def(klass)[0]:
        return has_ancestor(super_class, ancestor)
    else:
        return False


def class_props_type(klass_name):
    class_fields = list()
    if INLINE_INHERITED_PROPERTIES:
        class_fields.extend(get_class_property_fields_recursive(klass_name))
    else:
        class_fields.extend(get_filtered_class_property_fields(klass_name))
    if INLINE_INHERITED_CALLBACKS:
        class_fields.extend(get_class_signal_fields_recursive(klass_name, klass_name))
        class_fields.extend(get_class_bind_fields_recursive(klass_name, klass_name))
    else:
        class_fields.extend(get_class_signal_fields(klass_name, klass_name))
        class_fields.extend(get_class_bind_fields(klass_name, klass_name))
    class_fields = sorted(class_fields)
    property_definitions = ", ".join(": ".join(f) for f in class_fields)
    props_type_def = "{ " + property_definitions + " }"
    if not INLINE_INHERITED_PROPERTIES or not INLINE_INHERITED_CALLBACKS:
        super_class, _ = lookup_class_def(klass_name)
        if INLINE_INHERITED_CALLBACKS:
            super_class_type = f"{super_class}Props"
        else:
            super_class_type = f"{super_class}Props<{klass_name}>"
        props_type_def = super_class_type + " & " + props_type_def
    return props_type_def


def define_class(klass: ApiClass):
    klass_name = klass["Name"]
    if INLINE_ENTIRE_TYPE:
        props_type_def = class_props_type(klass_name)
    else:
        if klass_name in reference_count:
            props_type_def = f"{klass_name}Props<{klass_name}>"
        else:
            props_type_def = f"{klass_name}Props"

    return f"""\
\tlocal function {klass_name}(props: {props_type_def}, children)
\t\tapply(props)
\t\treturn e("{klass_name}", props, children)
\tend\
"""


def export_class(klass: ApiClass):
    name = klass["Name"]
    return f"""\
\t\t{name} = {name},\
"""


def define_base_type(name):
    class_fields = list()
    if not INLINE_INHERITED_PROPERTIES:
        class_fields.extend(get_filtered_class_property_fields(name))
    if not INLINE_INHERITED_CALLBACKS:
        class_fields.extend(get_class_signal_fields(name, "Rbx"))
        class_fields.extend(get_class_bind_fields(name, "Rbx"))
    class_fields = sorted(class_fields)
    super_class, _ = lookup_class_def(name)
    property_definitions = ", ".join(": ".join(f) for f in class_fields)
    props_suffix = "Props<Rbx>" if not INLINE_INHERITED_CALLBACKS else "Props"
    if super_class is None:
        return f"type {name}{props_suffix} = {{ {property_definitions} }}"
    elif class_fields:
        return f"type {name}{props_suffix} = {super_class}{props_suffix} & {{ {property_definitions} }}"
    else:
        return f"type {name}{props_suffix} = {super_class}{props_suffix}"


b_search: list[Literal["left", "right"]] = []  # Binary search for finding broken types
index = 0
min_index = 0
max_index = len(dump["Classes"])
# print(max_index, min_index)
for d in b_search:
    if d == "left":
        min_index += ceil((max_index - min_index) / 2)
    elif d == "right":
        max_index -= floor((max_index - min_index) / 2)
    # print(max_index, min_index)


def filter_class(klass: ApiClass):
    global index
    index += 1
    if index > max_index or index < min_index:
        return False
    tags = klass.get("Tags")
    if tags is None:
        tags = []
    return (
        "NotCreatable" not in tags
        and "Deprecated" not in tags
        and lookup_class_def(klass["Name"])[0]
        and any(has_ancestor(klass["Name"], s) for s in INCLUDE)
        and not any(has_ancestor(klass["Name"], s) for s in EXCLUDE)
    )


filtered_classes = list(filter(filter_class, dump["Classes"]))


@cache
def count_references(klass):
    super_class, _ = lookup_class_def(klass)
    if super_class:
        reference_count[super_class] += 1
        count_references(super_class)


for klass in filtered_classes:
    count_references(klass["Name"])

top_lines: list[str] = list()
if not INLINE_CALLBACKS:
    top_lines.append("type Event<Rbx, A...> = (rbx: Rbx, A...) -> ()")
    top_lines.append("type BindProperty<Rbx> = (rbx: Rbx) -> ()")
if not INLINE_INHERITED_PROPERTIES or not INLINE_INHERITED_CALLBACKS:
    top_lines.extend(map(define_base_type, reference_count.keys()))
if not INLINE_ENTIRE_TYPE:
    top_lines.extend(
        map(
            lambda name: f"type {name}Props = {class_props_type(name)}",
            (
                klass["Name"]
                for klass in filtered_classes
                if klass["Name"] not in reference_count
            ),
        )
    )
if len(top_lines) > 0:
    top_lines.insert(0, "-- stylua: ignore start")
    top_lines.append("-- stylua: ignore end")

body_lines = list()

body_lines.append(
    """\
\tlocal function apply(props: any)
\t\tlocal toRemove = {}
\t\tfor name, value in props do
\t\t\tif typeof(name) == "string" then
\t\t\t\tif name:sub(1, 2) == "on" then
\t\t\t\t\tprops[(config.Roact.Event :: any)[name:sub(3)]] = value
\t\t\t\t\ttoRemove[name] = true
\t\t\t\telseif name:sub(1, 4) == "bind" then
\t\t\t\t\tprops[(config.Roact.Change :: any)[name:sub(5)]] = value
\t\t\t\t\ttoRemove[name] = true
\t\t\t\tend
\t\t\tend
\t\tend
\t\tfor name, _ in toRemove do
\t\t\tprops[name] = nil
\t\tend
\t\tif props.ref then
\t\t\tprops[config.Roact.Ref] = props.ref
\t\t\tprops.ref = nil
\t\tend
\tend\
"""
)
body_lines.append("\t-- stylua: ignore start")
body_lines.extend(map(define_class, filtered_classes))
body_lines.append("\t-- stylua: ignore end")
exports = "\n".join(map(export_class, filtered_classes))

content = (
    content.replace("\t-- FROACTFUL_FUNCTION_BODY", "\n".join(body_lines))
    .replace("\t\t-- FROACTFUL_FUNCTION_EXPORTS", exports)
    .replace("-- FROACTFUL_FUNCTION_TOP", "\n".join(top_lines))
)
print("-- This file is generated by generate.py and not intended to be edited.")
print(content)
