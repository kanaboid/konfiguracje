# konfiguracje

Osobiste ustawienia i skrypt bootstrap do szybkiej konfiguracji nowego systemu Linux (Mint, Ubuntu, Debian).

Repozytorium zawiera konfigurację **Alacritty**, **tmux** oraz skrypt `install.sh`, który instaluje wymagane programy i podpina pliki ustawień do katalogu domowego.

---

## Szybki start

Na nowym komputerze:

```bash
git clone git@github.com:kanaboid/konfiguracje.git
cd konfiguracje
./install.sh
```

Potem:

```bash
source ~/.bashrc
alacritty
```

W tmux, jeśli pluginy się nie zainstalowały automatycznie: **Ctrl+b**, potem **I**.

---

## Struktura repozytorium

```
konfiguracje/
├── install.sh          # instalacja programów + symlinki do $HOME
├── README.md
└── linux/              # odwzorowanie katalogu domowego ($HOME)
    ├── .alacritty.toml
    ├── .tmux.conf
    └── .config/
        └── alacritty/
            └── themes/ # motywy kolorystyczne
```

Katalog `linux/` **odwzorowuje `$HOME`**. Plik `linux/.tmux.conf` odpowiada `~/.tmux.conf`, a `linux/.config/alacritty/...` — `~/.config/alacritty/...`.

---

## Co robi `install.sh`

| Krok | Opis |
|------|------|
| Pakiety APT | `git`, `tmux`, `xclip`, zależności do kompilacji Alacritty, czcionka JetBrains |
| Rust | instalacja przez `rustup`, jeśli brak |
| Alacritty | instalacja wersji **0.14.0** przez `cargo` + terminfo |
| TPM | tmux plugin manager (`~/.tmux/plugins/tpm`) |
| Dotfiles | symlinki z `linux/` do `$HOME` |
| Pluginy tmux | nordtheme i pozostałe z `.tmux.conf` |
| Git | automatyczne przekierowanie `https://github.com/` → SSH |

---

## Wymagania

- system oparty o Debian/Ubuntu (np. Linux Mint)
- dostęp do `sudo`
- klucz **SSH** skonfigurowany na GitHubie (do klonowania repo)

---

## Dodawanie nowych ustawień

1. Dodaj plik do `linux/` w tej samej ścieżce, w jakiej ma leżeć w katalogu domowym.
2. Zatwierdź zmiany w git i wypchnij na GitHub.

Przykład — konfiguracja Neovim:

```bash
mkdir -p linux/.config/nvim
cp ~/.config/nvim/init.lua linux/.config/nvim/
git add linux/.config/nvim/init.lua
git commit -m "Dodaj config nvim"
git push
```

Na nowym systemie wystarczy ponownie uruchomić `./install.sh` — skrypt utworzy brakujące symlinki.

---

## Dostosowanie instalacji

Inna wersja Alacritty:

```bash
ALACRITTY_VERSION=0.17.0 ./install.sh
```

---

## Zawartość `linux/`

| Plik / katalog | Opis |
|----------------|------|
| `.alacritty.toml` | terminal Alacritty (motyw, czcionka, przezroczystość) |
| `.tmux.conf` | tmux — nawigacja vim-style, TPM, motyw nord |
| `.config/alacritty/themes/` | kolekcja motywów kolorystycznych |

---

## Aktualizacja na już skonfigurowanym systemie

```bash
cd ~/konfiguracje
git pull
./install.sh
```

Symlinki wskazują na pliki w repo — po `git pull` zmiany w ustawieniach są widoczne od razu (Alacritty przeładowuje config automatycznie, tmux wymaga restartu sesji lub `tmux source-file ~/.tmux.conf`).
