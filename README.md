# hyprland-dotfiles

Мой рабочий стол на Hyprland для **Ubuntu**. За основу взяты [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (illogical-impulse, оболочка на Quickshell). Описание оригинала лежит в [.github/README.upstream.md](.github/README.upstream.md).

## Отличия от upstream

**Ubuntu**
- `sdata/dist-ubuntu/install-deps.sh` — установщик зависимостей через apt и PPA, без Nix. Рассчитан на Ubuntu 26.04 и новее.
- `./setup install` сам определяет Ubuntu и запускает этот установщик.

**Hyprland** (`dots/.config/hypr/custom/`)
- `layoutmodes.lua` — режимы раскладки на каждом воркспейсе в стиле awesomewm: dwindle → floating → scrolling, переключение по `Super+Shift+Space`. В floating-режиме новые окна ставятся туда, где не перекрывают другие. `Super+M` разворачивает окно на весь экран, при этом окно остаётся floating и корректно уходит под другие окна и поднимается над ними.
- `alttab.lua` — `Alt+Tab` переключает окна текущего воркспейса, начиная с последних использованных.
- `keybinds.lua` — фокус на `Super+H/J/K/L`, блокировка на `Super+Shift+L`, закрыть окно — `Super+Shift+C`, меню сессии — `Super+Shift+Q`.
- `general.lua` — раскладки us/ru (переключение `Alt+Shift`), Caps Lock и Ctrl поменяны местами, Compose на правом Alt.
- `env.lua` — Qt берёт тему GTK вместо KDE.
- `hyprland/general.lua` — масштаб монитора **1.20**. На другой машине поменяйте под свой экран.
- `hyprland/execs.lua` — курсор DMZ-White 28, gnome-keyring.

**Quickshell** (`dots/.config/quickshell/ii/`)
- Индикатор режима раскладки на вертикальном баре (`LayoutModeIndicator.qml`), клик по нему переключает режим.
- Мелкие исправления виджетов.

**Интеграция с GNOME вместо KDE**
- Файловый диалог из GNOME (`xdg-desktop-portal-gnome`), файловый менеджер Nautilus.
- Приложения по умолчанию из стандартного списка Ubuntu (`gnome-mimeapps.list`).

**Kitty** — zsh, прозрачность и размытие фона.

## Установка на новую машину

Нужна Ubuntu 26.04 или новее. Ставить можно прямо из сессии GNOME.

1. Склонируйте репозиторий вместе с подмодулями:

   ```bash
   git clone --recurse-submodules git@github.com:h5vx/hyprland-dotfiles.git ~/Projects/hyprland-dotfiles
   ```

2. Запустите установщик. Он подключит PPA, поставит пакеты и скопирует конфиги в `~/.config`, по ходу задавая вопросы:

   ```bash
   cd ~/Projects/hyprland-dotfiles && ./setup install
   ```

3. Включите интеграцию с GNOME: файловый диалог, Nautilus, приложения по умолчанию.

   ```bash
   ~/Projects/hyprland-dotfiles/extras/gnome-integration/install.sh
   ```

4. Выйдите из системы и на экране входа выберите сессию **Hyprland** (шестерёнка внизу).

5. Поправьте масштаб монитора под свой экран: `scale` в `~/.config/hypr/hyprland/general.lua`.

> **Если на машине уже был этот конфиг:** установщик не перезаписывает существующие файлы в `~/.config/hypr/custom/`, чтобы не затереть локальные правки. Свежие версии оттуда нужно скопировать вручную:
>
> ```bash
> cp -r ~/Projects/hyprland-dotfiles/dots/.config/hypr/custom/. ~/.config/hypr/custom/
> ```
>
> Остальные конфиги (`hypr/hyprland`, `quickshell`, `kitty` и т.д.) установщик синхронизирует и перезаписывает. Предупреждение об этом он показывает перед копированием.

## Обновление из upstream

```bash
git fetch upstream && git merge upstream/main
```

После слияния повторите `./setup install`.

## Сохранить изменения с этой машины обратно в репозиторий

Личные настройки Hyprland:

```bash
cp -r ~/.config/hypr/custom/. ~/Projects/hyprland-dotfiles/dots/.config/hypr/custom/
```

Затем сделайте коммит и `git push`.

## Лицензия

GPL-3.0, как у upstream (см. [LICENSE](LICENSE)).
