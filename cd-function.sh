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