# Quickstart
```bash
git clone https://www.github.com/edlwang/dotfiles.git "$HOME/dotfiles/"
bash "$HOME/dotfiles/init.sh"
```

## Starship
```bash
mkdir -p ~/.local/bin
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
```

## uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## venv
```bash
uv venv py313 --seed
```

## Global Git Config
```bash
git config --global url."git@github.com:edlwang/".insteadOf https://github.com/edlwang/
git config --global url."git@github.com:AIQ-Kitware/".insteadOf https://github.com/AIQ-Kitware/
git config --global alias.co checkout
git config --global alias.submodpull 'submodule update --init --recursive'
```

