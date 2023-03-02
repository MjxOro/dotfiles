# Install Instructions

- This dotfiles repo uses stow to link dotfiles. Using the scripts will require some apps to be pre-installed. Instructions of installations listed below

- install scripts only works for ubuntu or mac machines.

#### Mac

1. Install Brew

```
# Installing brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- Follow instructions given from brew installation to put in PATH

2. Install oh-my-zsh

```
# Installing oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

3. Install dotfiles

```
git clone https://github.com/MjxOro/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh && ./installs/link_files.sh
```

---

#### Ubuntu

1. Install oh-my-zsh

```
# Installing oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

2. Install dotfiles

```
git clone https://github.com/MjxOro/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh && ./installs/link_files.sh
```

---

# Uninstall

- Full uninstall Instructions are WIP.
- To unlink files, locate dotfiles directory and run `./installs/unlink_files.sh`

---

# dotfiles
