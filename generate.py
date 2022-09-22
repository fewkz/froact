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
    # They may break luau-lsp because they're new and not defined yet
    "CanvasGroup",
    "AdGui",
]
# Whether froactful tries to simplify types by unioning super class types.
# luau doesn't properly infer parameters to signals when they're not completely inlined.
INLINE_INHERITED_PROPERTIES = False
INLINE_INHERITED_SIGNALS = False
INLINE_ENTIRE_TYPE = False
INLINE_SIGNALS = False

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


def fix_property_definition(type_def: str):
    if type_def == "Content":
        return "string"
    elif type_def.startswith("Enum"):
        return "Enum." + type_def.removeprefix("Enum")
    elif type_def in ("Team", "Player"):
        return "any"
    else:
        return type_def


# self_type is either class name or Rbx
def fix_signal_defintion(type_def: str, self_type: str):
    if match := (
        re.match(r"RBXScriptSignal\<\((.*)\)\>", type_def)
        or re.match(r"RBXScriptSignal\<(.*)\>", type_def)
    ):
        args = tuple(
            fix_property_definition(x) for x in filter(None, match.group(1).split(", "))
        )
        args_def = ", ".join((self_type,) + args)
        if INLINE_SIGNALS:
            return f"(rbx: {args_def}) -> ()?"
        else:
            return f"Event<{args_def}>?"
    else:
        raise Exception("Couldn't match signal definition " + type_def)


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
        (name, make_optional(fix_property_definition(type_def)))
        for (name, type_def) in property_fields
        if type_def not in ignored_types and filter_class_field(klass, name)
    )


@cache
def get_class_signal_fields(klass: str, self_type):
    fields = get_parsed_class_fields(klass)
    signal_fields = {f for f in fields if f[1].startswith("RBXScriptSignal")}
    return tuple(
        ("on" + name, fix_signal_defintion(type_def, self_type))
        for (name, type_def) in signal_fields
    )


@cache
def get_class_fields(klass: str, self_type: str):
    return get_class_property_fields(klass) + get_class_signal_fields(klass, self_type)


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
    class_fields = get_parsed_class_fields(klass_name)
    if super_class:
        class_fields += get_parsed_class_fields_recursive(super_class)
    return class_fields


@cache
def get_class_property_fields_recursive(klass_name: str):
    super_class, _ = lookup_class_def(klass_name)
    class_fields = get_class_property_fields(klass_name)
    if super_class:
        class_fields += get_class_property_fields_recursive(super_class)
    return class_fields


@cache
def get_class_signal_fields_recursive(klass_name: str, self_type: str):
    super_class, _ = lookup_class_def(klass_name)
    class_fields = get_class_signal_fields(klass_name, self_type)
    if super_class:
        class_fields += get_class_signal_fields_recursive(super_class, self_type)
    return class_fields


@cache
def has_ancestor(klass, ancestor):
    if klass == ancestor:
        return True
    elif super_class := lookup_class_def(klass)[0]:
        return has_ancestor(super_class, ancestor)
    else:
        return False


@cache
def define_class_signals(klass: str):
    fields = get_parsed_class_fields_recursive(klass)
    signal_fields = sorted(f for f in fields if f[1].startswith("RBXScriptSignal"))
    signal_names = ", ".join('"' + f + '"' for (f, _) in signal_fields)
    return f"\n\t\tapplyEvent(props, {{ {signal_names} }})"
    # return tuple(
    #     f"\n\t\t(props :: any)[(config.Roact.Event :: any).{f}] = props.on{f};"
    #     for (f, _) in signal_fields
    # )


def class_props_type(klass_name):
    class_fields = list()
    if INLINE_INHERITED_PROPERTIES:
        class_fields.extend(get_class_property_fields_recursive(klass_name))
    else:
        class_fields.extend(get_class_property_fields(klass_name))
    if INLINE_INHERITED_SIGNALS:
        class_fields.extend(get_class_signal_fields_recursive(klass_name, klass_name))
    else:
        class_fields.extend(get_class_signal_fields(klass_name, klass_name))
    class_fields = sorted(class_fields)
    property_definitions = ", ".join(": ".join(f) for f in class_fields)
    props_type_def = "{ " + property_definitions + " }"
    if not INLINE_INHERITED_PROPERTIES or not INLINE_INHERITED_SIGNALS:
        super_class, _ = lookup_class_def(klass_name)
        if INLINE_INHERITED_SIGNALS:
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

    signal_definitions = define_class_signals(klass_name)

    return f"""\
\tlocal function {klass_name}(props: {props_type_def}, children){signal_definitions}
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
        class_fields.extend(get_class_property_fields(name))
    if not INLINE_INHERITED_SIGNALS:
        class_fields.extend(get_class_signal_fields(name, "Rbx"))
    class_fields = sorted(class_fields)
    super_class, _ = lookup_class_def(name)
    property_definitions = ", ".join(": ".join(f) for f in class_fields)
    props_suffix = "Props<Rbx>" if not INLINE_INHERITED_SIGNALS else "Props"
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
if not INLINE_SIGNALS:
    top_lines.append("\ttype Event<Rbx, A...> = (rbx: Rbx, A...) -> ()")
if not INLINE_INHERITED_PROPERTIES or not INLINE_INHERITED_SIGNALS:
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
top_lines.append("-- stylua: ignore")

body_lines = list()

body_lines.append(
    """\
\tlocal function applyEvent(props: any, tags: { any })
\t\tfor _, tag in tags do
\t\t\tprops[(config.Roact.Event :: any)[tag]] = props["on"..tag]
\t\t\tprops["on"..tag] = nil
\t\tend
\tend\
"""
)

body_lines.extend(map(define_class, filtered_classes))

exports = "\n".join(map(export_class, filtered_classes))

content = (
    content.replace("\t-- FROACTFUL_FUNCTION_BODY", "\n".join(body_lines))
    .replace("\t\t-- FROACTFUL_FUNCTION_EXPORTS", exports)
    .replace("-- FROACTFUL_FUNCTION_TOP", "\n".join(top_lines))
)
print("-- This file is generated by generate.py and not intended to be edited.")
print(content)
