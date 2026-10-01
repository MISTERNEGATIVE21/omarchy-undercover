# Part of OmaSettings. Sourced by bin/omasettings; not run on its own.

# ---------------------------------------------------------------- workspaces
#
# Which workspace an application opens on, and how its window arrives there:
# the `o.window("slack", { workspace = "3" })` lines people end up writing at
# the foot of hyprland.lua by hand. Ours land in the managed Lua like every
# other Hyprland setting, keyed by window class, so a rule survives the window
# it was made for and applies again the next time the application starts.
#
# A rule is an override in the Hyprland sense — remove it and the application
# goes back to opening wherever it was closed — so these rows carry Remove
# rather than a reset, the way bindings and compose sequences do.
#
# Rules the user wrote themselves are read and shown as "set in your own
# config"; a value picked here for the same class goes into our file, which
# loads last and therefore wins per property. Removing one comments their line
# out in place — see workspace_remove — and never regenerates their file.

# The class an application's windows carry, as best it can be known without
# running it. A desktop entry says so in StartupWMClass when it bothers to;
# otherwise the file's own name is the convention most toolkits follow.
#
# The casing is the trap: Slack's entry says "Slack" and its windows say
# "slack", and a Hyprland regex is case-sensitive. A running window is the
# truth, so where one is open under the same name in any case, its class is
# the one kept.
APPS_CACHE="${OMASETTINGS_APPS_CACHE:-${XDG_CACHE_HOME:-$HOME_DIR/.cache}/omarchy/omasettings/apps.json}"

# The desktop entries, parsed once per change to their directories. A hundred
# and sixty files are re-read on every state slice otherwise, and a slice is
# what answers a click; the running windows are merged in fresh each time
# since they are the cheap half and the half that changes.
workspace_desktop_entries() {
  local dirs=() dir stamp cached
  IFS=: read -ra dirs <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  dirs=("${XDG_DATA_HOME:-$HOME/.local/share}" "${dirs[@]}")

  stamp=$(for dir in "${dirs[@]}"; do [[ -d $dir/applications ]] && stat -c '%n %Y' "$dir/applications"; done | md5sum | cut -c1-32)
  if [[ -f $APPS_CACHE ]]; then
    cached=$(jq -c --arg s "$stamp" 'select(.stamp == $s) | .entries' "$APPS_CACHE" 2>/dev/null)
    [[ -n $cached ]] && { printf '%s\n' "$cached"; return 0; }
  fi

  local entries
  entries=$({
    for dir in "${dirs[@]}"; do
      [[ -d $dir/applications ]] || continue
      # Only the [Desktop Entry] group: actions below it carry their own Name.
      awk '
        FNR == 1 { name = ""; class = ""; hidden = 0; type = ""; ingroup = 0 }
        /^\[/ { ingroup = ($0 == "[Desktop Entry]"); next }
        !ingroup { next }
        /^Name=/ && name == "" { name = substr($0, 6) }
        /^StartupWMClass=/ { class = substr($0, 16) }
        /^NoDisplay=true/ || /^Hidden=true/ { hidden = 1 }
        /^Type=/ { type = substr($0, 6) }
        ENDFILE {
          if (!hidden && type == "Application" && name != "") {
            file = FILENAME
            sub(/.*\//, "", file); sub(/\.desktop$/, "", file)
            if (class == "") class = file
            print name "\t" class "\t" file
          }
        }' "$dir"/applications/*.desktop 2>/dev/null
    done
  } | jq -R -s -c '
    # An entry name wins the first time it appears: XDG_DATA_HOME comes first,
    # so a local override shadows the packaged file the way the launcher does.
    [ split("\n")[] | select(. != "") | split("\t")
      | { name: .[0], class: .[1], file: .[2] } ]
    | unique_by(.file)')
  mkdir -p "$(dirname "$APPS_CACHE")" 2>/dev/null
  jq -cn --arg s "$stamp" --argjson e "$entries" '{ stamp: $s, entries: $e }' >"$APPS_CACHE" 2>/dev/null
  printf '%s\n' "$entries"
}

workspace_apps() {
  local live entries
  live=$(capture hyprctl -j clients | jq -c '[.[] | .class] | map(select(. != "")) | unique' 2>/dev/null || echo '[]')
  entries=$(workspace_desktop_entries)
  jq -cn --argjson live "$live" --argjson entries "$entries" '
    $entries
    | (. as $entries
       | map(.class as $c
             | ($live | map(select(ascii_downcase == ($c | ascii_downcase))) | first) as $seen
             | { name: .name, class: ($seen // $c), running: ($seen != null), desktop: (.file + ".desktop") })
       # A window with no desktop entry — a script, a flatpak with an odd id —
       # is still something you might want on a workspace. It cannot be
       # started at login from here, though: nothing says how to launch it.
       + [ $live[] as $c
           | select(($entries | map(.class | ascii_downcase) | index($c | ascii_downcase)) == null)
           | { name: $c, class: $c, running: true, desktop: "" } ])
    | unique_by(.class)
    | sort_by(.name | ascii_downcase)'
}


# Their own o.window("<class>", { ... }) lines, one call per line, read from
# every Lua under the Hyprland directory except ours. A match given as a table
# ({ class = ..., title = ... }) is a rule about more than a class and is left
# to say nothing rather than be half understood.
workspace_config_rules() {
  local file line class body out='{}'
  while IFS= read -r line; do
    class=$(sed -nE 's/^[[:space:]]*o\.window\("([^"]+)",[[:space:]]*\{(.*)\}\).*/\1/p' <<<"$line")
    [[ -n $class ]] || continue
    body=$(sed -nE 's/^[[:space:]]*o\.window\("[^"]+",[[:space:]]*\{(.*)\}\).*/\1/p' <<<"$line")
    out=$(jq -c --arg c "$class" --arg body "$body" '
      # capture yields nothing rather than null when the key is absent, and a
      # nothing bound with `as` empties the whole filter — hence the array.
      def field($k): ([$body | capture("(^|,)\\s*" + $k + "\\s*=\\s*(?<v>\"[^\"]*\"|[a-z0-9.]+)")] | first
                      | if . == null then null else .v | ltrimstr("\"") | rtrimstr("\"") end);
      def bool($k): field($k) | if . == "true" then true elif . == "false" then false else null end;
      field("workspace") as $ws
      | .[$c] = ((.[$c] // {})
          + (if $ws == null then {} else
               { workspace: ($ws | split(" ")[0]), silent: ($ws | endswith(" silent")) } end)
          + (if bool("float") == null then {} else { float: bool("float") } end)
          + (if bool("fullscreen") == null then {} else { fullscreen: bool("fullscreen") } end)
          + (if bool("pin") == null then {} else { pin: bool("pin") } end)
          + (if bool("no_initial_focus") == null then {} else { no_initial_focus: bool("no_initial_focus") } end)
          + (if bool("no_screen_share") == null then {} else { no_screen_share: bool("no_screen_share") } end)
          + (if field("idle_inhibit") == null then {} else { idle_inhibit: (field("idle_inhibit") != "none") } end)
          + (if field("monitor") == null then {} else { monitor: field("monitor") } end))
      | with_entries(select(.value != {}))' <<<"$out")
  done < <(for file in "$HYPR_DIR"/*.lua; do
             [[ -f $file ]] || continue
             [[ $file == "$MANAGED_LUA" ]] && continue
             grep -E '^[[:space:]]*o\.window\("' "$file" 2>/dev/null
           done)
  printf '%s\n' "$out"
}

# Their own `o.launch_on_start("<id>.desktop")` lines, as the desktop ids they
# name. Only a desktop id can be tied back to an application on the page; a
# bare command is theirs to keep.
workspace_config_autostart() {
  local file
  for file in "$HYPR_DIR"/*.lua; do
    [[ -f $file ]] || continue
    [[ $file == "$MANAGED_LUA" ]] && continue
    sed -nE 's/^[[:space:]]*o\.launch_on_start\("([^"]+\.desktop)"\).*/\1/p' "$file" 2>/dev/null
  done | jq -R -s -c '[ split("\n")[] | select(. != "") ]'
}

workspace_rules_ours() {
  jq -c '.windowRules // {}' <<<"$(read_store)"
}

# The page's model: every application that can be picked, and every rule in
# force — ours, theirs, or both for the same class, with ours on top since
# that is the order Hyprland applies them in.
workspaces_state() {
  local apps ours theirs
  apps=$(workspace_apps)
  ours=$(workspace_rules_ours)
  theirs=$(workspace_config_rules)
  local autostart
  autostart=$(workspace_config_autostart)
  jq -cn --argjson apps "$apps" --argjson ours "$ours" --argjson theirs "$theirs" --argjson autostart "$autostart" '
    def name_of($c): ($apps | map(select(.class == $c)) | first | .name) // $c;
    def desktop_of($c): ($apps | map(select(.class == $c)) | first | .desktop) // "";
    # An application they start at login is on the page even with no window
    # rule: it is a setting about that application, and this is its page.
    (($ours | keys) + ($theirs | keys)
     + [ $apps[] | .desktop as $d | select($d != "" and ($autostart | index($d)) != null) | .class ]
     | unique) as $classes
    | { apps: $apps,
        rules: [ $classes[] as $c
                 | ($ours[$c] // {}) as $o | ($theirs[$c] // {}) as $t
                 | { class: $c,
                     name: name_of($c),
                     workspace: ($o.workspace // $t.workspace // ""),
                     silent: ($o.silent // $t.silent // false),
                     float: ($o.float // $t.float // false),
                     fullscreen: ($o.fullscreen // $t.fullscreen // false),
                     shown: (if ($o.fullscreen // $t.fullscreen) == true then "fullscreen"
                             elif ($o.float // $t.float) == true then "floating" else "tiled" end),
                     monitor: ($o.monitor // $t.monitor // ""),
                     pin: ($o.pin // $t.pin // false),
                     width: ($o.width // (if $o.placement == "half" then 50 elif $o.placement == "large" then 70 elif $o.placement == "full" then 90 else 0 end)),
                     height: ($o.height // (if $o.placement == "half" then 50 elif $o.placement == "large" then 70 elif $o.placement == "full" then 90 else 0 end)),
                     center: ($o.center // ($o.placement != null)),
                     noInitialFocus: ($o.no_initial_focus // $t.no_initial_focus // false),
                     idleInhibit: ($o.idle_inhibit // $t.idle_inhibit // false),
                     noScreenShare: ($o.no_screen_share // $t.no_screen_share // false),
                     desktop: desktop_of($c),
                     autostart: ((($o.autostart // "") != "") or (desktop_of($c) != "" and ($autostart | index(desktop_of($c))) != null)),
                     ours: ($ours | has($c)),
                     theirs: ($t != {} or (desktop_of($c) != "" and ($autostart | index(desktop_of($c))) != null)) } ],
        setups: $setups }' --argjson setups "$(workspace_setups_state)"
}

# ------------------------------------------------------ the workspaces themselves
#
# A workspace rule is about the place rather than what opens there: which
# display it lives on, whether it is that display's default, whether it stays
# when empty, what it is called, how it lays windows out. Same store, same
# managed file, rendered as `hl.workspace_rule` — the second half of the page.

workspace_setups_ours() {
  jq -c '.workspaceRules // {}' <<<"$(read_store)"
}

# Their own single-line `hl.workspace_rule({ workspace = "N", ... })` calls,
# read the way window rules are. A `name:` selector is left alone: the page
# speaks in numbers.
workspace_setups_config() {
  local file line body out='{}'
  while IFS= read -r line; do
    body=$(sed -nE 's/^[[:space:]]*hl\.workspace_rule\([[:space:]]*\{(.*)\}[[:space:]]*\).*/\1/p' <<<"$line")
    [[ -n $body ]] || continue
    out=$(jq -c --arg body "$body" '
      def field($k): ([$body | capture("(^|,)\\s*" + $k + "\\s*=\\s*(?<v>\"[^\"]*\"|[a-z0-9.]+)")] | first
                      | if . == null then null else .v | ltrimstr("\"") | rtrimstr("\"") end);
      def bool($k): field($k) | if . == "true" then true elif . == "false" then false else null end;
      field("workspace") as $ws
      | if $ws == null or ($ws | test("^[0-9]+$") | not) then . else
        .[$ws] = ((.[$ws] // {})
          + (if field("monitor") == null then {} else { monitor: field("monitor") } end)
          + (if bool("default") == null then {} else { default: bool("default") } end)
          + (if bool("persistent") == null then {} else { persistent: bool("persistent") } end)
          + (if field("default_name") == null then {} else { name: field("default_name") } end)
          + (if field("layout") == null then {} else { layout: field("layout") } end)
          + (if bool("decorate") == false and bool("no_border") == true then { minimal: true } else {} end))
        end' <<<"$out")
  done < <(for file in "$HYPR_DIR"/*.lua; do
             [[ -f $file ]] || continue
             [[ $file == "$MANAGED_LUA" ]] && continue
             grep -E '^[[:space:]]*hl\.workspace_rule\(' "$file" 2>/dev/null
           done)
  printf '%s\n' "$out"
}

workspace_setups_state() {
  local ours theirs
  ours=$(workspace_setups_ours)
  theirs=$(workspace_setups_config)
  jq -cn --argjson ours "$ours" --argjson theirs "$theirs" '
    (($ours | keys) + ($theirs | keys) | unique | sort_by(tonumber)) as $ids
    | [ $ids[] as $i
        | ($ours[$i] // {}) as $o | ($theirs[$i] // {}) as $t
        | { id: $i,
            label: ("Workspace " + $i),
            monitor: ($o.monitor // $t.monitor // ""),
            default: ($o.default // $t.default // false),
            persistent: ($o.persistent // $t.persistent // false),
            name: ($o.name // $t.name // ""),
            layout: ($o.layout // $t.layout // ""),
            minimal: ($o.minimal // $t.minimal // false),
            ours: ($ours | has($i)),
            theirs: ($t != {}) } ]'
}

workspace_setup_add() {
  local id=$1
  [[ $id =~ ^[0-9]+$ ]] || die "'$id' is not a workspace number"
  edit_store '.workspaceRules = ((.workspaceRules // {}) | .[$i] = (.[$i] // {}))' --arg i "$id"
}

workspace_setup_set() {
  local id=$1 field=$2 value=$3 json
  [[ $id =~ ^[0-9]+$ ]] || die "'$id' is not a workspace number"
  case $field in
    monitor|name)
      [[ -z $value || $value =~ ^[^\"\\]+$ ]] || die "'$value' cannot go in a Lua string"
      json=$(jq -Rn --arg v "$value" '$v') ;;
    layout)
      [[ -z $value || $value =~ ^[a-z]+$ ]] || die "'$value' is not a layout"
      json=$(jq -Rn --arg v "$value" '$v') ;;
    default|persistent|minimal)
      [[ $value == true || $value == false ]] || die "'$value' is not true or false"
      json=$value ;;
    *) die "unknown workspace setting '$field'" ;;
  esac
  # Off and empty mean "no rule", as they do for a window: a workspace with
  # `persistent = false` written down is not the same as one never mentioned.
  edit_store '.workspaceRules = ((.workspaceRules // {})
    | .[$i] = ((.[$i] // {}) | if $v == "" or $v == false then del(.[$f]) else .[$f] = $v end))' \
    --arg i "$id" --arg f "$field" --argjson v "$json"
  hyprctl reload >/dev/null 2>&1 || true
}

# Ours goes; a line they wrote is commented out in place, as a window rule is.
workspace_setup_remove() {
  local id=$1 file previous
  [[ $id =~ ^[0-9]+$ ]] || die "'$id' is not a workspace number"
  edit_store '.workspaceRules = ((.workspaceRules // {}) | del(.[$i]))' --arg i "$id"

  for file in "$HYPR_DIR"/*.lua; do
    [[ -f $file ]] || continue
    [[ $file == "$MANAGED_LUA" ]] && continue
    read_file "$file" | grep -qE "^[[:space:]]*hl\.workspace_rule\([[:space:]]*\{[[:space:]]*workspace *= *\"$id\"" || continue
    previous=$(read_file "$file")
    backup_once "$file"
    awk -v id="$id" '
      $0 ~ /^[ \t]*hl\.workspace_rule\(/ && $0 ~ ("workspace *= *\"" id "\"") {
        print "-- " $0
        print "-- ^ removed in OmaSettings; delete the dashes to bring it back."
        next
      }
      { print }
    ' <(read_file "$file") | write_file "$file" managed
    if ! capture luac -p "$file" >/dev/null; then
      printf '%s' "$previous" | write_file "$file" managed
      die "removing that rule would have broken $(basename "$file"), so nothing changed"
    fi
  done
  hyprctl reload >/dev/null 2>&1 || true
}

render_workspace_setups_lua() {
  local rules
  rules=$(workspace_setups_ours)
  [[ $rules == "{}" ]] && return 0
  echo ""
  echo "-- Workspaces set up from the Workspaces page."
  jq -r 'to_entries[] | select(.value != {})
    | .value as $r
    | [ (if ($r.monitor // "") != "" then "monitor = \"" + $r.monitor + "\"" else empty end),
        (if $r.default == true then "default = true" else empty end),
        (if $r.persistent == true then "persistent = true" else empty end),
        (if ($r.name // "") != "" then "default_name = \"" + $r.name + "\"" else empty end),
        (if ($r.layout // "") != "" then "layout = \"" + $r.layout + "\"" else empty end),
        (if $r.minimal == true then "gaps_in = 0, gaps_out = 0, no_border = true, no_rounding = true, decorate = false" else empty end)
      ] as $fields
    | select(($fields | length) > 0)
    | "hl.workspace_rule({ workspace = \"" + .key + "\", " + ($fields | join(", ")) + " })"' <<<"$rules"
}

# One field of one class. A class is a regex to Hyprland, so the two
# characters that would break the Lua string are refused rather than escaped.
workspace_set() {
  local class=$1 field=$2 value=$3 json
  [[ -n $class ]] || die "no application given"
  [[ $class =~ ^[^\"\\]+$ ]] || die "'$class' is not a window class"
  case $field in
    workspace)
      [[ -z $value || $value =~ ^[0-9]+$ || $value == special ]] || die "'$value' is not a workspace"
      json=$(jq -Rn --arg v "$value" '$v') ;;
    silent|float|fullscreen|pin|no_initial_focus|idle_inhibit|no_screen_share)
      [[ $value == true || $value == false ]] || die "'$value' is not true or false"
      json=$value ;;
    monitor)
      [[ -z $value || $value =~ ^[^\"\\]+$ ]] || die "'$value' is not a display"
      json=$(jq -Rn --arg v "$value" '$v') ;;
    # A floating window's size, as a share of the screen it opens on, so the
    # same rule fits a laptop panel and a 4K monitor. Coordinates stay Lua's.
    width|height)
      [[ -z $value || ( $value =~ ^[0-9]+$ && $value -ge 10 && $value -le 100 ) ]] \
        || die "'$value' is not a percentage between 10 and 100"
      json=${value:-\"\"} ;;
    center)
      [[ $value == true || $value == false ]] || die "'$value' is not true or false"
      json=$value ;;
    # Started at login by desktop id, which is what uwsm launches by; the
    # value is the id so the render needs nothing but the store.
    autostart)
      [[ -z $value || $value =~ ^[A-Za-z0-9._@+-]+\.desktop$ ]] || die "'$value' is not a desktop entry"
      json=$(jq -Rn --arg v "$value" '$v') ;;
    # How the window shows: one of three, since a fullscreen window is neither
    # tiled nor floating in any way you can see. Stored as the two Hyprland
    # fields, never both at once.
    shown)
      case $value in
        tiled) json='{}' ;;
        floating) json='{"float":true}' ;;
        fullscreen) json='{"fullscreen":true}' ;;
        *) die "'$value' is not tiled, floating or fullscreen" ;;
      esac
      workspace_write "$class" '.[$c] = ((.[$c] // {}) | del(.float) | del(.fullscreen) + $v
        | if .float != true then del(.pin) | del(.placement) | del(.width) | del(.height) | del(.center) else . end)' --argjson v "$json"
      return 0 ;;
    *) die "unknown window setting '$field'" ;;
  esac

  # An empty workspace or a switch turned off is the absence of the rule, not
  # a rule saying so: `float = false` would pin a window tiled against the
  # user's own config, which is more than "off" promises.
  # Turning one of float and fullscreen on turns the other off, so a rule can
  # never ask for both.
  # Pinning and placement only mean anything floating; a window that stops
  # floating stops carrying them rather than keeping a promise Hyprland will
  # ignore.
  workspace_write "$class" '.[$c] = ((.[$c] // {})
        | if $v == "" or $v == false then del(.[$f]) else .[$f] = $v end
        | if $v == true and $f == "float" then del(.fullscreen)
          elif $v == true and $f == "fullscreen" then del(.float) else . end
        | if $f == "float" and $v != true then del(.pin) | del(.placement) | del(.width) | del(.height) | del(.center) else . end)' \
    --arg f "$field" --argjson v "$json"
  return 0
}

# One edit of a class's rule, then only what that edit needs: Hyprland is told
# to reload when the rendered file actually changed — flipping a switch to the
# value it already had is not a reason to re-run the whole config — and the
# open windows are brought in line either way.
workspace_write() {
  local class=$1 filter=$2 before after
  shift 2
  before=$(md5sum <"$MANAGED_LUA" 2>/dev/null)
  edit_store ".windowRules = ((.windowRules // {}) | $filter)" --arg c "$class" "$@"
  after=$(md5sum <"$MANAGED_LUA" 2>/dev/null)
  [[ $before != "$after" ]] && { hyprctl reload >/dev/null 2>&1 || true; }
  workspace_apply_live "$class"
}

# A window rule applies to windows that open from now on. The ones already
# open are what the user is looking at, so the rule in force is applied to them
# as well — otherwise "Shown as: Floating" leaves a fullscreen window
# fullscreen, and an application that remembers how it was closed (Typora,
# most Electron apps) opens fullscreen again next time however the rule reads.
#
# Through `hyprctl eval`, not `hyprctl dispatch`: on a Lua config the latter
# parses its argument as Lua, so the old `movetoworkspacesilent 7,class:...`
# form fails — and did so silently here for a while.
workspace_apply_live() {
  local class=$1 rule ws float fullscreen addr floating lua
  rule=$(jq -c --arg c "$class" '(.windowRules // {})[$c] // {}' <<<"$(read_store)")
  ws=$(jq -r '.workspace // ""' <<<"$rule")
  float=$(jq -r '.float // false' <<<"$rule")
  fullscreen=$(jq -r '.fullscreen // false' <<<"$rule")

  while IFS=$'\t' read -r addr floating; do
    [[ -n $addr ]] || continue
    lua="local w = 'address:$addr'"
    # Fullscreen mode 2 is what the rule gives a window; 0 takes it back.
    lua+="; hl.dispatch(hl.dsp.window.fullscreen_state({ internal = $([[ $fullscreen == true ]] && echo 2 || echo 0), client = 0, window = w }))"
    # The float dispatcher toggles whatever it is told — every key tried
    # (action, state, mode, floating) flipped the window — so it is sent only
    # to a window that is on the wrong side.
    [[ $floating != "$float" ]] && lua+="; hl.dispatch(hl.dsp.window.float({ window = w }))"
    # A workspace is only a place to go; "wherever it was" moves nothing.
    [[ -n $ws ]] && lua+="; hl.dispatch(hl.dsp.window.move({ workspace = '$ws', follow = false, window = w }))"
    hyprctl eval "$lua" >/dev/null 2>&1 </dev/null || true
  done < <(capture hyprctl -j clients \
           | jq -r --arg c "$class" '.[] | select(.class == $c) | "\(.address)\t\(.floating)"' 2>/dev/null)
}

# Drops our rule, and takes a line the user wrote for the same class with it.
#
# Their line is commented out rather than deleted, the way a device block is:
# it is their config, and a rule that turns out to have been wanted should be
# recoverable by deleting two dashes rather than from a backup. Only the
# single-line `o.window("<class>", { ... })` form is touched — the same one
# that is read — and the file is checked with `luac -p` afterwards and put
# back if the edit broke it.
workspace_remove() {
  local class=$1 file previous desktop
  [[ -n $class ]] || die "no application given"
  desktop=$(workspace_apps | jq -r --arg c "$class" 'map(select(.class == $c)) | first | .desktop // ""')
  edit_store '.windowRules = ((.windowRules // {}) | del(.[$c]))' --arg c "$class"

  for file in "$HYPR_DIR"/*.lua; do
    [[ -f $file ]] || continue
    [[ $file == "$MANAGED_LUA" ]] && continue
    read_file "$file" | grep -qE "^[[:space:]]*o\.window\(\"$(sed 's/[][\\.*^$|?+(){}]/\\&/g' <<<"$class")\",|^[[:space:]]*o\.launch_on_start\(\"$(sed 's/[][\\.*^$|?+(){}]/\\&/g' <<<"$desktop")\"\)" || continue

    previous=$(read_file "$file")
    backup_once "$file"

    awk -v class="$class" -v desktop="$desktop" '
      (index($0, "o.window(\"" class "\",") && $0 ~ /^[ \t]*o\.window\(/) \
      || (desktop != "" && index($0, "o.launch_on_start(\"" desktop "\")") && $0 ~ /^[ \t]*o\.launch_on_start\(/) {
        print "-- " $0
        print "-- ^ removed in OmaSettings; delete the dashes to bring it back."
        next
      }
      { print }
    ' <(read_file "$file") | write_file "$file" managed

    if ! capture luac -p "$file" >/dev/null; then
      printf '%s' "$previous" | write_file "$file" managed
      die "removing that rule would have broken $(basename "$file"), so nothing changed"
    fi
  done

  hyprctl reload >/dev/null 2>&1 || true
}

# Add an application to the page with nothing set yet, so it has a group to
# be configured in. An empty rule renders nothing until a field arrives.
workspace_add() {
  local class=$1
  [[ -n $class ]] || die "no application given"
  [[ $class =~ ^[^\"\\]+$ ]] || die "'$class' is not a window class"
  edit_store '.windowRules = ((.windowRules // {}) | .[$c] = (.[$c] // {}))' --arg c "$class"
}

# Lua for the managed file: one o.window call per class, in the shape the
# hand-written ones take so the two read alike side by side.
render_window_rules_lua() {
  local rules
  rules=$(workspace_rules_ours)
  [[ $rules == "{}" ]] && return 0
  echo ""
  echo "-- Applications bound to a workspace, from the Workspaces page."
  jq -r 'to_entries[] | select(.value != {})
    | .value as $r
    | [ (if ($r.workspace // "") != "" then
           "workspace = \"" + $r.workspace + (if $r.silent == true then " silent" else "" end) + "\""
         else empty end),
        (if $r.float == true then "float = true" else empty end),
        (if $r.fullscreen == true then "fullscreen = true" else empty end),
        (if $r.pin == true then "pin = true" else empty end),
        (if ($r.monitor // "") != "" then "monitor = \"" + $r.monitor + "\"" else empty end),
        # A size needs both halves; one alone falls back to the same share of
        # the other axis. Presets written by an earlier version still render.
        (($r.width // (if $r.placement == "half" then 50 elif $r.placement == "large" then 70 elif $r.placement == "full" then 90 else null end)) as $w
         | ($r.height // (if $r.placement == "half" then 50 elif $r.placement == "large" then 70 elif $r.placement == "full" then 90 else null end)) as $h
         | if $w == null and $h == null then empty
           else "size = {\"monitor_w * \(($w // $h) / 100)\", \"monitor_h * \(($h // $w) / 100)\"}" end),
        (if $r.center == true or ($r.placement != null and $r.center == null) then "center = true" else empty end),
        (if $r.no_initial_focus == true then "no_initial_focus = true" else empty end),
        (if $r.idle_inhibit == true then "idle_inhibit = \"always\"" else empty end),
        (if $r.no_screen_share == true then "no_screen_share = true" else empty end) ] as $fields
    | select(($fields | length) > 0)
    | "o.window(\"" + .key + "\", { " + ($fields | join(", ")) + " })"' <<<"$rules"

  # Omarchy'"'"'s own helper, so the line reads like the one its autostart.lua
  # suggests writing, and launches through uwsm the way the launcher does.
  jq -r 'to_entries[] | select((.value.autostart // "") != "")
    | "o.launch_on_start(\"" + .value.autostart + "\")"' <<<"$rules"
}

workspaces_cmd() {
  case ${1:-} in
    state) workspaces_state ;;
    add) workspace_add "${2:-}" ;;
    set) workspace_set "${2:-}" "${3:-}" "${4:-}" ;;
    remove) workspace_remove "${2:-}" ;;
    setup)
      case ${2:-} in
        add) workspace_setup_add "${3:-}" ;;
        set) workspace_setup_set "${3:-}" "${4:-}" "${5:-}" ;;
        remove) workspace_setup_remove "${3:-}" ;;
        *) die "usage: omasettings workspaces setup add <n> | set <n> monitor|default|persistent|name|layout|minimal <value> | remove <n>" ;;
      esac ;;
    *) die "usage: omasettings workspaces state | add <class> | set <class> <field> <value> | remove <class> | setup ..." ;;
  esac
}
