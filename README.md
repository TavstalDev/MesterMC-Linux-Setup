# MesterMC Linux Telepítő és Indító Szkript

[![Licenc](https://img.shields.io/badge/licenc-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/TavstalDev/MesterMC-Linux-Setup?style=social)](https://github.com/TavstalDev/MesterMC-Linux-Setup/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/TavstalDev/MesterMC-Linux-Setup?style=social)](https://github.com/TavstalDev/MesterMC-Linux-Setup/network/members)

Ez a Bash szkript célja, hogy leegyszerűsítse a MesterMC játék kliens telepítését és beállítását Linux operációs rendszereken Wine és OpenJDK 21 használatával. Automatikus folyamatot biztosít a függőségek telepítésétől a játékindító fájl generálásáig, beleértve a konzolmentes indítási lehetőséget.

## Tartalomjegyzék

* [Főbb Jellemzők](#főbb-jellemzők)
* [Támogatott Disztribúciók](#támogatott-disztribúciók)
* [Előfeltételek](#előfeltételek)
* [Használat](#használat)
* [Fontos Megjegyzések](#fontos-megjegyzések)
* [Hibaelhárítás](#hibaelhárítás)
* [Hozzájárulás](#hozzájárulás)
* [Licenc](#licenc)

## Főbb Jellemzők

* **Automatikus Wine telepítés:** Észleli az Ön Linux disztribúcióját (Debian/Ubuntu, Fedora, Arch Linux) és telepíti a stabil Wine verzióját.
* **OpenJDK 21 ellenőrzés és telepítés:** Biztosítja a MesterMC futtatásához szükséges Java környezetet.
* **Testreszabható Wine előtag (prefix):** Lehetőséget ad egyedi Wine prefix helyének megadására, ami hasznos lehet több Wine alkalmazás elkülönítéséhez.
* **PowerShell Wrapper telepítés:** Beállítja a szükséges Wine komponenseket a jobb kompatibilitás érdekében.
* **MesterMC kliens letöltése és telepítése:** Automatikusan letölti és futtatja a hivatalos MesterMC telepítőt a konfigurált Wine környezetben.
* **Rugalmas indító fájl generálása:**
    * **Shell szkript (.sh):** Egy egyszerű futtatható szkriptet hoz létre a terminálból történő indításhoz.
    * **Asztali indító (.desktop):** Egy felhasználóbarát asztali parancsikont generál, amely megjelenik az alkalmazásmenüben, és **rejtett konzollal** indítja a MesterMC-t, zökkenőmentes grafikus élményt biztosítva.
* **Telepítés utáni takarítás:** Eltávolítja a letöltött telepítőfájlokat a rendezett környezet fenntartása érdekében.

## Támogatott Disztribúciók

A szkript a következő Linux disztribúciókon történő Wine és OpenJDK telepítést támogatja:

* **Debian/Ubuntu** (és származékai, pl. Linux Mint, Pop!\_OS)
* **Fedora**
* **Arch Linux** (és származékai, pl. Manjaro)

Más disztribúciók esetén a Wine és OpenJDK manuális telepítésére lehet szükség.

## Előfeltételek

A szkript futtatása előtt győződjön meg róla, hogy:

* **Internetkapcsolat:** Szükséges a Wine, OpenJDK és a MesterMC telepítők letöltéséhez.
* **`sudo` jogosultságok:** A szkript rendszer szintű változtatásokat hajt végre (pl. Wine, OpenJDK telepítése), ehhez szüksége lesz a jelszavára.
* **`wget` telepítve van:** A legtöbb disztribúción alapból telepítve van, de ha hiányzik, telepítse (pl. `sudo apt install wget` vagy `sudo dnf install wget`).
* **`lsb_release` telepítve van:** Debian/Ubuntu alapú rendszereken a disztribúció kódnevének észleléséhez szükséges. Ha hiányzik: `sudo apt install lsb-release`.
* **`grep` telepítve van:** Fedora rendszeren a verzió észleléséhez szükséges.

## Használat

1.  **Szkript letöltése:**
    Nyisson meg egy terminált, és töltse le a szkriptet a GitHubról:
    ```bash
    wget [https://raw.githubusercontent.com/TavstalDev/MesterMC-Linux-Setup/main/setup_mestermc.sh](https://raw.githubusercontent.com/TavstalDev/MesterMC-Linux-Setup/main/setup_mestermc.sh) -O setup_mestermc.sh
    ```

2.  **Végrehajthatóvá tétel:**
    Adjon végrehajtási engedélyt a szkriptnek:
    ```bash
    chmod +x setup_mestermc.sh
    ```

3.  **Szkript futtatása:**
    Indítsa el a szkriptet a terminálból:
    ```bash
    ./setup_mestermc.sh
    ```

4.  **Kövesse az utasításokat:**
    * A szkript kérni fogja a **`sudo` jelszavát** a Wine és OpenJDK telepítéséhez.
    * Megkérdezi az **opcionális Wine előtag** helyét. Nyomjon Entert az alapértelmezett (~/.wine) használatához, vagy adja meg a kívánt elérési utat (pl. `~/.wine_mestermc`).
    * Letölti és futtatja a PowerShell Wrappert, majd a MesterMC telepítőt. Kövesse a MesterMC telepítőjének lépéseit.
    * Végül megkérdezi, hogy **shell szkript (.sh)** vagy **asztali indító (.desktop)** fájlt szeretne-e generálni. Válassza a "desktop" opciót a konzolmentes indításhoz és az alkalmazásmenü integrációhoz.

## Fontos Megjegyzések

* **Wine előtag:** A szkript által beállított `WINEPREFIX` környezeti változó kulcsfontosságú. Ha manuálisan szeretné futtatni a MesterMC-t a generált indító nélkül, mindig állítsa be ezt a változót, mielőtt Wine parancsot ad ki (pl. `export WINEPREFIX="/útvonal/a/wineprefixhez"`).
* **Asztali indító (`.desktop`):**
    * A szkript az asztali indítót úgy konfigurálja, hogy a `javaw.exe` programot használja a MesterMC indításához. Ez a Windows-os Java verzió felelős azért, hogy **ne nyíljon meg konzolablak** az alkalmazás futtatásakor. A Linuxon futó `java` parancsot a szkript csak a telepítés ellenőrzésére használja.
    * Az ikon elérési útja a Wine prefixen belüli `icon.ico` fájlra mutat. Győződjön meg róla, hogy ez a fájl létezik a MesterMC telepítési könyvtárában.
    * Ha az indítót áthelyezi az alkalmazások mappájába (`~/.local/share/applications/`), akkor az megjelenik az alkalmazásmenüben. Előfordulhat, hogy újra kell indítania a grafikus felületet, vagy ki kell jelentkeznie/be kell jelentkeznie, hogy azonnal látható legyen.
* **Arch Linux multilib:** Az Arch Linuxon a Wine telepítéséhez engedélyeznie kell a `multilib` tárolót a `/etc/pacman.conf` fájlban. A szkript figyelmeztetést ad, ha ez a lépés szükséges.
* **MesterMC telepítő:** A MesterMC telepítője során felbukkanhatnak Windows-os ablakok, amelyeket manuálisan kell kezelnie (pl. "Tovább", "Elfogadom" gombokra kattintás).

## Hibaelhárítás

Íme néhány gyakori probléma és azok lehetséges megoldásai:

* **`sudo` jelszóval kapcsolatos problémák:** Győződjön meg róla, hogy helyes jelszót ad meg, és felhasználója szerepel a `sudoers` csoportban.
* **Internetkapcsolati hibák:** Ellenőrizze internetkapcsolatát, és próbálja újra a szkriptet.
* **Wine telepítés sikertelen:**
    * **Debian/Ubuntu:** Ellenőrizze, hogy a `DISTRO_CODENAME` helyesen lett-e észlelve, és hogy az Ön disztribúciója támogatott-e a WineHQ által. Előfordulhat, hogy a `winehq-archive.key` letöltésekor van probléma, vagy a tároló hozzáadása nem sikerült.
    * **Fedora:** Ellenőrizze, hogy a `FEDORA_VERSION` helyes-e.
    * **Arch Linux:** Győződjön meg róla, hogy a `multilib` tároló engedélyezve van a `/etc/pacman.conf` fájlban (távolítsa el a `#` jelet a `[multilib]` és az alatta lévő `Include = /etc/pacman.d/mirrorlist` sorok elől, majd futtasson `sudo pacman -Sy` parancsot).
* **OpenJDK 21 telepítés sikertelen:** Ellenőrizze, hogy az Ön disztribúciójának csomagkezelőjében (`apt`, `dnf`, `pacman`) elérhető-e az OpenJDK 21. Előfordulhat, hogy frissítenie kell a csomaglistákat (`sudo apt update` / `sudo dnf update` / `sudo pacman -Sy`).
* **`MesterMC.jar` nem található:**
    * Győződjön meg róla, hogy a MesterMC telepítője sikeresen lefutott, és telepítette a `.jar` fájlt a Wine prefixen belül a `C:\users\<YOUR_LINUX_USERNAME>\AppData\Roaming\MesterMC\` útvonalra.
    * Ellenőrizze, hogy a Wine prefix helyesen lett-e beállítva a szkriptben.
* **MesterMC nem indul el, vagy hibát jelez:**
    * Próbálja meg manuálisan elindítani a `MesterMC.jar` fájlt a Wine fájlkezelőjéből (futtassa a `wine explorer` parancsot a terminálban a helyes `WINEPREFIX` beállítása után, majd navigáljon az alkalmazás elérési útjára és kattintson duplán a `.jar` fájlra).
    * Ellenőrizze a Java telepítését a Wine prefixen belül.
    * Nézze meg a Wine konzol kimenetét hibákért (futtassa az indítót egy terminálból a `nohup` és `&` nélkül).

## Hozzájárulás

Szívesen fogadunk minden hozzájárulást a szkript fejlesztéséhez! Ha hibát talál, vagy javaslata van a javításra, kérjük:

1.  Forkolja a tárolót.
2.  Hozzon létre egy új branch-et (`git checkout -b feature/AmazingFeature`).
3.  Végezze el a módosításokat.
4.  Commitolja a változtatásait (`git commit -m 'Add some AmazingFeature'`).
5.  Pusholja a branch-et (`git push origin feature/AmazingFeature`).
6.  Nyisson egy Pull Request-et.

## Licenc

Ez a projekt az MIT Licenc alatt van kiadva. Részletekért lásd a [LICENSE](LICENSE) fájlt.
