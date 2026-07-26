#!/usr/bin/env bash
#
# DESIGN リポジトリのスキルを対話的に選択し、Claude Code のスキルディレクトリに登録する。
#
# 使い方:
#   curl -fsSL https://raw.githubusercontent.com/Himeyama/DESIGN/main/scripts/install.sh | bash
#   ./scripts/install.sh --scope user
#   ./scripts/install.sh --scope project --skills csharp-coding,shell-scripting --force
#
# jq が必要です。未インストールの場合は自動でのインストールを試みます
# （brew / apt / dnf / yum / pacman / apk / zypper のいずれかが必要）。
#
# `curl ... | bash` のようにパイプ経由で実行すると標準入力(fd 0)はスクリプト
# 本体の読み込みに使われてしまうため、対話 UI 用のキー入力は /dev/tty (fd 3)
# から直接読む。制御端末が無い環境（cron 等）では HAS_TTY=0 となり、
# --skills / --scope による非対話実行が必要になる。

set -euo pipefail

if exec 3<>/dev/tty 2>/dev/null; then
    HAS_TTY=1
else
    HAS_TTY=0
fi

REPO_OWNER="Himeyama"
REPO_NAME="DESIGN"
BRANCH="main"
API_ROOT="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"
RAW_ROOT="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"

SCOPE=""
SKILLS=""
FORCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scope)
            SCOPE="$2"
            shift 2
            ;;
        --skills)
            SKILLS="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        *)
            echo "不明な引数です: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -n "$SCOPE" && "$SCOPE" != "user" && "$SCOPE" != "project" ]]; then
    echo "--scope は user か project を指定してください" >&2
    exit 1
fi

install_jq() {
    echo "jq が見つかりません。インストールを試みます..." >&2

    local sudo_cmd=""
    if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
        sudo_cmd="sudo"
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install jq
    elif command -v apt-get >/dev/null 2>&1; then
        $sudo_cmd apt-get update && $sudo_cmd apt-get install -y jq
    elif command -v dnf >/dev/null 2>&1; then
        $sudo_cmd dnf install -y jq
    elif command -v yum >/dev/null 2>&1; then
        $sudo_cmd yum install -y jq
    elif command -v pacman >/dev/null 2>&1; then
        $sudo_cmd pacman -Sy --noconfirm jq
    elif command -v apk >/dev/null 2>&1; then
        $sudo_cmd apk add jq
    elif command -v zypper >/dev/null 2>&1; then
        $sudo_cmd zypper install -y jq
    else
        echo "対応するパッケージマネージャーが見つかりませんでした。jq を手動でインストールしてください（brew install jq / apt install jq など）。" >&2
        exit 1
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    install_jq
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq のインストールに失敗しました。手動でインストールしてください。" >&2
        exit 1
    fi
    echo "jq をインストールしました。" >&2
fi

get_github_directory() {
    local path="$1"
    curl -fsSL -H "User-Agent: DESIGN-installer" "$API_ROOT/$path?ref=$BRANCH"
}

# 複数選択 UI。$1: 選択肢名を格納した配列変数名, $2: 結果を格納する配列変数名
select_skills() {
    local -n names_ref="$1"
    local -n result_ref="$2"
    local n=${#names_ref[@]}
    local -a selected
    local i cursor=0

    for ((i = 0; i < n; i++)); do selected[i]=0; done

    while true; do
        clear
        echo "登録するスキルを選択してください (↑/↓: 移動, Space: 選択, A: 全選択, Enter: 決定)"
        echo
        for ((i = 0; i < n; i++)); do
            local prefix=" " mark=" "
            [[ $i -eq $cursor ]] && prefix=">"
            [[ ${selected[i]} -eq 1 ]] && mark="x"
            echo "$prefix [$mark] ${names_ref[i]}"
        done

        local key rest
        IFS= read -rsn1 key <&3
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.01 rest <&3 || true
            key+="$rest"
        fi

        case "$key" in
            $'\x1b[A'|k|K) cursor=$(( (cursor - 1 + n) % n )) ;;
            $'\x1b[B'|j|J) cursor=$(( (cursor + 1) % n )) ;;
            " ") selected[cursor]=$((1 - selected[cursor])) ;;
            a|A)
                local all_selected=1
                for ((i = 0; i < n; i++)); do
                    if [[ ${selected[i]} -eq 0 ]]; then
                        all_selected=0
                        break
                    fi
                done
                local newval=$((1 - all_selected))
                for ((i = 0; i < n; i++)); do selected[i]=$newval; done
                ;;
            ""|$'\n'|$'\r')
                result_ref=()
                for ((i = 0; i < n; i++)); do
                    [[ ${selected[i]} -eq 1 ]] && result_ref+=("${names_ref[i]}")
                done
                return 0
                ;;
        esac
    done
}

# 単一選択 UI。$1: タイトル, $2: 選択肢名を格納した配列変数名, 標準出力に選ばれたラベルを出力
select_single_option() {
    local title="$1"
    local -n labels_ref="$2"
    local n=${#labels_ref[@]}
    local i cursor=0

    while true; do
        clear
        echo "$title (↑/↓: 移動, Enter: 決定)"
        echo
        for ((i = 0; i < n; i++)); do
            local prefix=" "
            [[ $i -eq $cursor ]] && prefix=">"
            echo "$prefix ${labels_ref[i]}"
        done

        local key rest
        IFS= read -rsn1 key <&3
        if [[ $key == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.01 rest <&3 || true
            key+="$rest"
        fi

        case "$key" in
            $'\x1b[A'|k|K) cursor=$(( (cursor - 1 + n) % n )) ;;
            $'\x1b[B'|j|J) cursor=$(( (cursor + 1) % n )) ;;
            ""|$'\n'|$'\r')
                echo "${labels_ref[cursor]}"
                return 0
                ;;
        esac
    done
}

get_destination_root() {
    local chosen_scope="$SCOPE"

    if [[ -z "$chosen_scope" ]]; then
        local -a labels=("user" "project")
        chosen_scope="$(select_single_option "インストール先を選択してください" labels)"
    fi

    if [[ "$chosen_scope" == "user" ]]; then
        echo "$HOME/.claude/skills"
    else
        echo "$(pwd)/.claude/skills"
    fi
}

install_skill() {
    local name="$1"
    local destination_root="$2"
    local dest_dir="$destination_root/$name"

    if [[ -e "$dest_dir" && $FORCE -eq 0 ]]; then
        local answer=""
        if [[ $HAS_TTY -eq 1 ]]; then
            read -rp "既に存在します: $dest_dir を上書きしますか？ [y/N]: " answer <&3
        fi
        if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
            echo "スキップ: $name"
            return 1
        fi
    fi

    mkdir -p "$dest_dir"

    local entries
    entries="$(get_github_directory "skills/$name")"

    if echo "$entries" | jq -e 'any(.[]; .type == "file" and .name == "skill.md")' >/dev/null; then
        curl -fsSL "$RAW_ROOT/skills/$name/skill.md" -o "$dest_dir/SKILL.md"
    fi

    if echo "$entries" | jq -e 'any(.[]; .type == "dir" and .name == "examples")' >/dev/null; then
        local examples_dir="$dest_dir/examples"
        mkdir -p "$examples_dir"

        local example_entries
        example_entries="$(get_github_directory "skills/$name/examples")"
        local example_name
        while IFS= read -r example_name; do
            curl -fsSL "$RAW_ROOT/skills/$name/examples/$example_name" -o "$examples_dir/$example_name"
        done < <(echo "$example_entries" | jq -r '.[] | select(.type == "file") | .name')
    fi

    echo "インストール完了: $name -> $dest_dir"
    return 0
}

echo "スキル一覧を取得しています..."
root_entries="$(get_github_directory "skills")"
mapfile -t skill_dirs < <(echo "$root_entries" | jq -r '.[] | select(.type == "dir") | .name')

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    echo "スキル一覧の取得に失敗しました。" >&2
    exit 1
fi

declare -a chosen=()

if [[ -n "$SKILLS" ]]; then
    IFS=',' read -ra requested <<< "$SKILLS"
    declare -a missing=()
    for name in "${requested[@]}"; do
        name="$(echo "$name" | xargs)"
        [[ -z "$name" ]] && continue
        if printf '%s\n' "${skill_dirs[@]}" | grep -qx "$name"; then
            chosen+=("$name")
        else
            missing+=("$name")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "警告: 存在しないスキル名を無視しました: ${missing[*]}" >&2
    fi
elif [[ $HAS_TTY -eq 0 ]]; then
    echo "対話的な選択には制御端末 (/dev/tty) が必要です。cron などの非対話環境では使えません。代わりに次のいずれかを使ってください:" >&2
    echo "  bash ./scripts/install.sh --skills <name1>,<name2>" >&2
    exit 1
else
    select_skills skill_dirs chosen
fi

if [[ ${#chosen[@]} -eq 0 ]]; then
    echo "選択されたスキルがありません。終了します。"
    exit 0
fi

destination_root="$(get_destination_root)"

declare -a installed=()
for name in "${chosen[@]}"; do
    if install_skill "$name" "$destination_root"; then
        installed+=("$name")
    fi
done

echo
echo "=== 完了 ==="
if [[ ${#installed[@]} -eq 0 ]]; then
    echo "インストールされたスキルはありません。"
else
    for name in "${installed[@]}"; do
        echo " - $name -> $destination_root/$name"
    done
fi
