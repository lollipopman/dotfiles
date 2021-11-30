### Keep the config free of passwords

In `$GIT_DIR/info/attributes`:

    config filter=irssi

In `$GIT_DIR/config`:

    [filter "irssi"]
      clean = "sed -Ee 's/(\\w*sasl_password = )"(.*)";$/\\1"<PASSWORD>";/'"
