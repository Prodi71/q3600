# OpenWrt 25.12.6 · Xiaomi AX3600 · все kmod + vermagic

Сборка прошивки `qualcommax/ipq807x`, **всех** kernel-модулей пакетами и их
совместимость со **стоковой** прошивкой того же релиза.

## Запуск
1. Содержимое этой папки — в корень репозитория (`.github/` должен быть в корне).
2. Actions → «AX3600 · OpenWrt · all kmods» → Run workflow.
3. Артефакты: `packages-*` (все .apk/.ipk, включая все kmod), `firmware-*` (образы,
   манифест, итоговый .config, vermagic).

Локально: `OWRT_VER=25.12.6 bash scripts/local-build.sh` (~25–40 ГБ диска).

## Про vermagic
Это не «25.12.6», а 32-hex ABI-хэш kernel-пакета (`kernel_6.12.x-r1-<hash>_...`).
Каждый kmod зависит от `kernel (= <ver>-<hash>)`. Пайплайн:
1. воспроизводит официальный конфиг (`config.buildinfo` + `feeds.buildinfo` + тот же тег);
2. форсирует хэш (`.vermagic`, литерал в `include/*.mk`, `LINUX_VERMAGIC=` в make);
3. сверяет результат и **падает** при расхождении.

Форс — косметика метаданных; реальную совместимость даёт только идентичный конфиг ядра.

## Ключевые решения
* Список пакетов применяется как **`=y`** (это манифест рабочей системы).
  `=m` для `base-files`/`netifd`/`luci` дал бы роутер без сети и LuCI.
* «Все kmod в packages» обеспечивает `CONFIG_ALL_KMODS=y` — они собираются `=m`
  и в образ не вшиваются.
* Конфликты вариантов сняты в `ax3600.config` (dnsmasq, wpad, ustream/uhttpd, ip, nftables).
* Шаг `10-config.sh` валидирует имена по `tmp/.packageinfo`, печатает таблицу
  «запрошено → что есть в дереве» и сам удаляет несуществующие.

## Установка на роутер
```sh
apk add --allow-untrusted ./kmod-xxx-*.apk    # 25.12
opkg install ./kmod-xxx_*.ipk                 # 24.10 и старше