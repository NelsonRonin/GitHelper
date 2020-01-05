#!/bin/bash

# ------------------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------------------
CONFIG_FILE=~/gh-config.txt

declare -A CONFIG_PARAMS
CONFIG_PARAMS[aliases]="aliases_setd="
CONFIG_PARAMS[projectsRoot]="projects_root_dir="

# ------------------------------------------------------------------------------------------
# PRINT FUNCTIONS
# ------------------------------------------------------------------------------------------
show() {
  echo -e "$1"
}
showInfo() {
  # check number of args and not empty string
  if [ $# == 2 ] && [ -n "$2" ]; then
    show "\e[1;44m $1 \e[34;49m $2 \e[0m"
  elif [ $# == 1 ] && [ -n "$1" ]; then
    show "\e[34m $1 \e[0m"
  fi
}
showSuccess() {
  # check number of args and not empty string
  if [ $# == 2 ] && [ -n "$2" ]; then
    show "\e[1;42m $1 \e[32;49m $2 \e[0m"
  elif [ $# == 1 ] && [ -n "$1" ]; then
    show "\e[32m $1 \e[0m"
  fi
}
showWarn() {
  # check number of args and not empty string
  if [ $# == 2 ] && [ -n "$2" ]; then
    show "\e[1;43m $1 \e[33;49m $2 \e[0m"
  elif [ $# == 1 ] && [ -n "$1" ]; then
    show "\e[33m $1 \e[0m"
  fi
}
showError() {
  # check number of args and not empty string
  if [ $# == 2 ] && [ -n "$2" ]; then
    show "\e[1;41m $1 \e[31;49m $2 \e[0m"
  elif [ $# == 1 ] && [ -n "$1" ]; then
    show "\e[31m $1 \e[0m"
  fi
}

# ------------------------------------------------------------------------------------------
# File Handling Functions
# ------------------------------------------------------------------------------------------
writeLineToFile() {
  FILE=$1
  LINE=$2

  ### set config file if it does not exist
  if [ ! -e "$FILE" ]; then
    touch $FILE
  fi

  ### set correct permissions on config file if not set yet
  if [ ! -r "$FILE" ] || [ ! -w "$FILE" ]; then
    sudo chmod 755 $FILE
  fi

  echo "$LINE" >>"$FILE"
}

# ------------------------------------------------------------------------------------------
# GIT HELPERS
# ------------------------------------------------------------------------------------------
installGit() {
  git --version
  GIT_IS_AVAILABLE=$?

  if [ $GIT_IS_AVAILABLE -ne 0 ]; then
    showInfo "INSTALLATION" "Starting to install git..."
    sudo apt install git-all
  else
    showInfo "INSTALLATION" "Git is already installed"
  fi
}

upgradeGit() {
  while true; do
    read -p "Do you want to try to upgrade Git? [y/n]:" -r yn
    case $yn in
    [Yy]*)
      sudo apt install git-all
      break
      ;;
    [Nn]*) return ;;
    *) echo "Please enter exactly Y/y or N/n..." ;;
    esac
  done
}

setGitUser() {
  USER_NAME=$1
  USER_EMAIL=$2

  git config --global user.name "$USER_NAME" >/dev/null
  git config --global user.email "$USER_EMAIL" >/dev/null
}

setGitAliases() {
  ALIASES_FILE=~/.bash_aliases

  while true; do
    read -p "Do you want to set alias for git (g=git)? [y/n]:" -r yn
    case $yn in
    [Yy]*)
      writeLineToFile $ALIASES_FILE "alias g='git'"
      source $ALIASES_FILE
      break
      ;;
    [Nn]*)
      return 0
      break
      ;;
    *) echo "Please enter exactly Y/y or N/n..." ;;
    esac
  done

  git config --global alias.conf-name config --global user.name >/dev/null
  git config --global alias.conf-email config --global user.email >/dev/null
  git config --global alias.in init >/dev/null
  git config --global alias.cl clone >/dev/null
  git config --global alias.co checkout >/dev/null
  git config --global alias.cob checkout -b >/dev/null
  git config --global alias.rao remote add origin >/dev/null
  git config --global alias.st status >/dev/null
  git config --global alias.a add >/dev/null
  git config --global alias.aa add -A >/dev/null
  git config --global alias.cm commit -m >/dev/null
  git config --global alias.ac add -A && git commit >/dev/null
  git config --global alias.pu push >/dev/null
  git config --global alias.puo push -u origin >/dev/null
  git config --global alias.brd branch -d >/dev/null
  git config --global alias.brD branch -D >/dev/null
  git config --global alias.rbm rebase origin/master >/dev/null
  git config --global alias.frbm fetch origin master && git rebase origin/master >/dev/null
  git config --global alias.mrg merge >/dev/null
  git config --global alias.dff diff >/dev/null
  git config --global alias.lrr remote -v >/dev/null
  git config --global alias.lb branch >/dev/null
  git config --global alias.lconf config --list >/dev/null
}

setUserDirectoryListener() {
  ### check if user enters(opens) user directory and change git user if so
  PROFILE_FILE=~/.bash_profile

  ### create profile file if it does not exist yet
  if [ ! -e "$PROFILE_FILE" ]; then
    touch $PROFILE_FILE
  fi

  ### set correct permissions on profile file if not set yet
  if [ ! -r "$PROFILE_FILE" ] || [ ! -w "$PROFILE_FILE" ]; then
    sudo chmod 755 $PROFILE_FILE
  fi

  ### read directory listener line line from profile file
  DIR_LISTENER_EXISTS=0
  while IFS= read -r line; do
    if [[ "$line" == "function cd() {"* ]]; then
      DIR_LISTENER_EXISTS=1
    fi
  done <"$PROFILE_FILE"

  if [ $DIR_LISTENER_EXISTS -eq 0 ]; then
    showInfo "USER DIRECTORY LISTENER" "For all your set user directories, we set a listener, which switches your git user in the config, if you open the directory"

    cat >$PROFILE_FILE <<'EOL'
function cd() {
  # actually change the directory with all args passed to the function
  builtin cd "$@" || return

  CONFIG_FILE=~/gh-config.txt
  git config --global user.name >/dev/null
  ACTIVE_USER_NAME=$?

  ### todo: check if cd in projects root directory

  ### get username from given path
  NEW_USER_NAME=""
  IFS=/ read -ra values <<< "$@"
  for dir in "${values[@]}";do
    while IFS= read -r line; do
      if [[ "$line" == "$dir"* ]]; then
        NEW_USER_NAME="$dir"
      fi
    done < "$CONFIG_FILE"
  done

  ### check if directory is git user directory
  if [ "$NEW_USER_NAME" != "" ] && [ "$ACTIVE_USER_NAME" != "$NEW_USER_NAME" ]; then
    USER_CONFIG=""

    ### read the user line from githelper config file
    while IFS= read -r line; do
      if [[ "$line" == "$NEW_USER_NAME"* ]]; then
        USER_CONFIG="$line"
      fi
    done < "$CONFIG_FILE"

    if [ "$USER_CONFIG" != "" ]; then
      USER_EMAIL=$(cut -d '=' -f2 <<< "$USER_CONFIG")

      git config --global user.name "$NEW_USER_NAME"
      git config --global user.email "$USER_EMAIL"

      echo -e "\e[1;42m Changed Git User \e[32;49m Your git user config was changed to: $NEW_USER_NAME - $USER_EMAIL \e[0m"
    fi
  fi
}
EOL
  else
    showInfo "USER DIRECTORY LISTENER" "The user directory listener is already added and ready to switch your user config"
  fi

  source $PROFILE_FILE
}

generateSSHKeyPair() {
  USER_NAME=$1
  USER_EMAIL=$2
  SSH_PATH="$HOME/.ssh/id_rsa_$USER_NAME"

  ssh-keygen -t rsa -b 4096 -C "$USER_EMAIL" <<<"$SSH_PATH"
  ssh-add "$SSH_PATH"

  showInfo "ADD SSH KEY TO GIT" "Now copy the following ssh public key and add it to your account. "
  showInfo "HOW TO ADD" "Described here: https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account"
  cat "$SSH_PATH.pub"

  showSuccess "DONE" "Your git account is now all setup with ssh key connection"
}

setSshKeyPairForAccount() {
  while true; do
    read -p "Do you want to set an SSH key pair for this account? [y/n]:" -r yn
    case $yn in
    [Yy]*)
      generateSSHKeyPair "$1" "$2"
      break
      ;;
    [Nn]*)
      return 0
      break
      ;;
    *) echo "Please enter exactly Y/y or N/n..." ;;
    esac
  done
}

# ------------------------------------------------------------------------------------------
# GitHelper Functions
# ------------------------------------------------------------------------------------------
gitHelperInfo() {
  showInfo "MISSING/WRONG ARGUMENT" "Please call this script with one of the following arguments:"
  showInfo "install  :    to install everything necessary for git"
  showInfo "add-user :    to add a new user (account) to the git config (changes account and sets new account directory)"
}

setBashAliases() {
  ALIASES_FILE=~/.bash_aliases

  writeLineToFile $ALIASES_FILE "alias gconf-name='git config --global user.name'"
  writeLineToFile $ALIASES_FILE "alias gconf-email='git config --global user.email'"
  writeLineToFile $ALIASES_FILE "alias gin='git init'"
  writeLineToFile $ALIASES_FILE "alias gcl='git clone'"
  writeLineToFile $ALIASES_FILE "alias gco='git checkout'"
  writeLineToFile $ALIASES_FILE "alias gcob='git checkout -b'"
  writeLineToFile $ALIASES_FILE "alias grao='git remote add origin'"
  writeLineToFile $ALIASES_FILE "alias gst='git status'"
  writeLineToFile $ALIASES_FILE "alias ga='git add'"
  writeLineToFile $ALIASES_FILE "alias gaa='git add -A'"
  writeLineToFile $ALIASES_FILE "alias gcm='git commit -m'"
  writeLineToFile $ALIASES_FILE "alias gac='!git add -A && git commit'"
  writeLineToFile $ALIASES_FILE "alias gpu='git push'"
  writeLineToFile $ALIASES_FILE "alias gpuo='git push -u origin'"
  writeLineToFile $ALIASES_FILE "alias gbrd='git branch -d'"
  writeLineToFile $ALIASES_FILE "alias gbrD='git branch -D'"
  writeLineToFile $ALIASES_FILE "alias grbm='git rebase origin/master'"
  writeLineToFile $ALIASES_FILE "alias gfrbm='git fetch origin master && git rebase origin/master'"
  writeLineToFile $ALIASES_FILE "alias gmrg='git merge'"
  writeLineToFile $ALIASES_FILE "alias gdff='git diff'"
  writeLineToFile $ALIASES_FILE "alias glrr='git remote -v'"
  writeLineToFile $ALIASES_FILE "alias glb='git branch'"
  writeLineToFile $ALIASES_FILE "alias glconf='git config --list'"

  source $ALIASES_FILE
}

gitHelperInstall() {
  # ------------------------------------------------------------
  # Installation
  # ------------------------------------------------------------
  ### check if git is installed and install if not
  installGit
  ### Upgrade git to newest version if user wants to
  upgradeGit
  showSuccess "INSTALLED AND UPDATED" "You now have the latest version of git on your system!"

  # ------------------------------------------------------------
  # Aliases
  # ------------------------------------------------------------
  ### read aliases config line from githelper config file
  ALIASES_CONFIG=""
  if [ -e "$CONFIG_FILE" ]; then
    while IFS= read -r line; do
      if [[ "$line" == "${CONFIG_PARAMS[aliases]}"* ]]; then
        ALIASES_CONFIG="$line"
      fi
    done <"$CONFIG_FILE"
  fi

  if [ "$ALIASES_CONFIG" == "" ]; then
    while true; do
      read -p "Do you want to set Git-Aliases or Bash-Aliases (commit with git: g cm, with bash: gcm) ? [g/b]:" -r ALIASES_TYPE
      case $ALIASES_TYPE in
      [g])
        ALIASES_TYPE="git"
        break
        ;;
      [b])
        ALIASES_TYPE="bash"
        break
        ;;
      *) echo "Please enter exactly 'g' for git or 'b' for bash..." ;;
      esac
    done

    if [ "$ALIASES_TYPE" == "git" ]; then
      setGitAliases
      writeLineToFile "$CONFIG_FILE" "${CONFIG_PARAMS[aliases]}1"
    elif [ "$ALIASES_TYPE" == "bash" ]; then
      setBashAliases
      writeLineToFile "$CONFIG_FILE" "${CONFIG_PARAMS[aliases]}1"
    fi
  else
    showInfo "ALIASES" "the necessary git aliases already exists..."
  fi

  showSuccess "GREAT" "Now we setd your new git aliases!"

  # ------------------------------------------------------------
  # Manage Accounts
  # ------------------------------------------------------------
  ### read project root config from githelper config file
  PROJECTS_ROOT_CONFIG=""
  if [ -e "$CONFIG_FILE" ]; then
    while IFS= read -r line; do
      if [[ "$line" == "${CONFIG_PARAMS[projectsRoot]}"* ]]; then
        PROJECTS_ROOT_CONFIG="$line"
      fi
    done <"$CONFIG_FILE"
  fi

  if [ "$PROJECTS_ROOT_CONFIG" == "" ]; then
    showInfo "PROJECTS ROOT DIRECTORY" "For better use we need the full path of the directory you want to contain all your git projects"
    read -e -p "Please enter the path of your git root directory: " -r PROJECTS_DIR

    ### set dir if does not exist
    if [ ! -d "$PROJECTS_DIR" ]; then
      install -d -m 0755 -o $USER -g $USER $PROJECTS_DIR
    fi
    ### save dir path to config file
    writeLineToFile "$CONFIG_FILE" "${CONFIG_PARAMS[projectsRoot]}$PROJECTS_DIR"
  fi

  ### add a first user to git config and gitHelper config with directory listener
  gitHelperAddUser

  ### add user directory listeners (change user config if enters users dir)
  setUserDirectoryListener
}

gitHelperAddUser() {
  showInfo "YOUR ACCOUNT" "Now you need to add your git account, so you will be able to work on your projects"

  showInfo "Add User" "Lets add a new user to your git config"
  read -p "Please enter your Git Username: " -r USER_NAME
  read -p "Please enter your Git Email: " -r USER_EMAIL

  ### set user directory and open directory
  install -d -m 0755 -o $USER -g $USER $PROJECTS_DIR/$USER_NAME

  ### add git config user data
  setGitUser "$USER_NAME" "$USER_EMAIL"
  ### save projects root directory to config file
  writeLineToFile "$CONFIG_FILE" "$USER_NAME=$USER_EMAIL"

  ### generate and add ssh key pair for new account (email)
  setSshKeyPairForAccount "$USER_NAME" "$USER_EMAIL"
}

# ------------------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------------------
showInfo "
    _____ _ _   _    _      _
   / ____(_) | | |  | |    | |"
showSuccess " | |  __ _| |_| |__| | ___| |_ __   ___ _ __
  | | |_ | | __|  __  |/ _ \ | '_ \ / _ \ '__|"
showError " | |__| | | |_| |  | |  __/ | |_) |  __/ |
   \_____|_|\__|_|  |_|\___|_| .__/ \___|_|
                             | |
                             |_|
"
showInfo "Welcome to GitHelper" "Setup git on your computer in only a few simple steps!"

### check if arguments exist
if [ $# -lt 1 ]; then
  gitHelperInfo
else
  COMMAND=$1

  if [ "$COMMAND" == "install" ]; then
    gitHelperInstall
  elif [ "$COMMAND" == "add-user" ]; then
    gitHelperAddUser
  else
    gitHelperInfo
  fi
fi

#fi

# ------------------------------------------------------------------------------------------
# HINTS
# ------------------------------------------------------------------------------------------
## PRINT HINTS
# thanks to escape sequences, ANSI/VT100
# -- TEXT COLOR ----------------
# Red:       \e[31m
# Green:     \e[32m
# Yellow:    \e[33m
# Blue:      \e[34m
# Magenta:   \e[95m
# Cyan:      \e[96m

# -- BACKGROUND COLOR ----------
# BgRed:     \e[41m
# BgGreen:   \e[42m
# BgYellow:  \e[43m
# BgBlue:    \e[44m
# BgMagenta: \e[45m
# BgCyan:    \e[46m

# -- STYLILNG ----------
# Bold:      \e[1m
# Dim:       \e[2m
# Underline: \e[4m
# Blink:     \e[5m
# Invert:    \e[7m
# Hidden:    \e[8m
