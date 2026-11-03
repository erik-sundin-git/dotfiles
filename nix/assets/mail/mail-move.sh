# mail-move: turn notmuch tags into Proton folder moves. Runs from notmuch's
# preNew hook, before mbsync pushes the result (programs/mail/notmuch.nix).
# Tags are the intent, folders are Proton's state. A move renames one file of
# the message into the target maildir without its ,U=<uid> part, so mbsync
# uploads it there and removes it from the old folder.
#
#   mail-move [--dry-run] [--spam]
#   MAIL_MOVE_FORCE=1   allow more than $max moves in one run
#   ~/Mail/.no-move     emergency stop: move nothing

base=$HOME/Mail
acct=proton
max=25
dry=0
spam=0
for arg in "$@"; do
  case $arg in
    --dry-run) dry=1 ;;
    --spam) spam=1 ;;
    *)
      echo "usage: mail-move [--dry-run] [--spam]" >&2
      exit 2
      ;;
  esac
done

if [[ -e $base/.no-move ]]; then
  echo "mail-move: $base/.no-move exists, moving nothing" >&2
  exit 0
fi

declare -A planned=()
srcs=()
dsts=()

# plan <target folder> <source folder regex> <query>
# For each matching message, pick one file (the INBOX copy if there is one)
# that mbsync has paired with Proton (,U= in its name) and that sits in an
# allowed source folder. Drafts, Labels/ and the local drafts dir never match.
plan() {
  local dst=$1 src_re=$2 query=$3 id f rel dir pick sub name
  while IFS= read -r -d '' id; do
    id=${id#id:}
    [[ -n ${planned[$id]:-} ]] && continue
    pick=
    while IFS= read -r -d '' f; do
      rel=${f#"$base/$acct/"}
      [[ $rel != "$f" ]] || continue
      dir=${rel%/*/*}
      [[ ${f##*/} == *,U=* ]] || continue
      [[ $dir =~ ^($src_re)$ ]] || continue
      if [[ -z $pick || $dir == INBOX ]]; then pick=$f; fi
    done < <(notmuch search --exclude=false --output=files --format=text0 "id:\"${id//\"/\"\"}\"")
    [[ -n $pick ]] || continue
    planned[$id]=1
    sub=${pick%/*}
    sub=${sub##*/}
    name=$(sed -E 's/,U=[0-9]+//' <<<"${pick##*/}")
    srcs+=("$pick")
    dsts+=("$base/$acct/$dst/$sub/$name")
  done < <(notmuch search --exclude=false --output=messages --format=text0 \
    "path:$acct/** and not tag:new and ($query)")
}

# Order is precedence: each message is planned at most once.
plan Trash 'INBOX|Archive|Sent|Spam|Folders/.+' \
  'tag:deleted and not folder:"proton/Trash"'
if ((spam)); then
  plan Spam 'INBOX|Archive|Folders/.+' \
    'tag:spam and not tag:deleted and not folder:"proton/Spam"'
fi
plan Archive 'INBOX' \
  'not tag:inbox and not tag:deleted and not tag:spam and folder:"proton/INBOX"'

n=${#srcs[@]}
((n > 0)) || exit 0

if ((dry)); then
  for i in "${!srcs[@]}"; do
    printf '%s -> %s\n' "${srcs[i]#"$base/"}" "${dsts[i]#"$base/"}"
  done
  exit 0
fi

if ((n > max)) && [[ ${MAIL_MOVE_FORCE:-} != 1 ]]; then
  echo "mail-move: $n moves planned (max $max). Check them with 'mail-move --dry-run'," >&2
  echo "then run 'MAIL_MOVE_FORCE=1 mail-move' once, or untag." >&2
  exit 1
fi

for i in "${!srcs[@]}"; do
  src=${srcs[i]}
  dst=${dsts[i]}
  mkdir -p "${dst%/*}"
  mv -n "$src" "$dst" || true
  if [[ -e $src ]]; then
    echo "mail-move: could not move $src to $dst" >&2
    exit 1
  fi
done
echo "mail-move: moved $n message(s)"
