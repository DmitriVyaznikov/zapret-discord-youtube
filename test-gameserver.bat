@echo off
chcp 65001 > nul
:: Тестовый файл для подбора desync-стратегии для игрового сервера (UDP 2302-2303)
:: Сервер: 51.89.93.157 (Genesis Epoch, ArmA 2)
:: Запускает ТОЛЬКО фильтр для игровых портов — минимальный winws для быстрого тестирования
::
:: ВАЖНО: перед каждым тестом убей предыдущий winws (закрой окно или taskkill /f /im winws.exe)

cd /d "%~dp0"

set "BIN=%~dp0bin\"
set "LISTS=%~dp0lists\"

:menu
cls
echo ================================================================
echo   Тест desync-стратегий для игрового сервера (UDP 2302-2303)
echo   Сервер: 51.89.93.157 (Genesis Epoch)
echo ================================================================
echo:
echo   --- A. Диагностика ---
echo   A. Без desync (проверка: zapret мешает или нет?)
echo:
echo   --- B. IP-фрагментация (новый подход) ---
echo   1. ipfrag2 (фрагментация IP-пакета, pos=8)
echo   2. ipfrag2 (фрагментация, pos=24)
echo   3. fake + ipfrag2 (комбо: фейк + фрагментация)
echo:
echo   --- C. UDP length manipulation ---
echo   4. udplen (изменение длины UDP, +2 байта)
echo   5. udplen (изменение длины UDP, +8 байт)
echo   6. fake + udplen (комбо)
echo:
echo   --- D. Fake с новыми параметрами ---
echo   7. fake + badsum fooling + autottl=2 + cutoff=n1
echo   8. fake + autottl=1 (минимальный delta) + cutoff=n1
echo   9. fake + stun.bin как фейк + autottl=2 + cutoff=n2
echo:
echo   --- E. Агрессивные комбинации ---
echo   10. fake + repeats=24 + autottl=2 + cutoff=n2
echo   11. fake + autottl=2 + cutoff=d200 (byte-based cutoff)
echo   12. fake + autottl=2 + cutoff=s1 (time-based cutoff, 1 сек)
echo:
echo   --- F. Старые рабочие (для сравнения) ---
echo   13. fake + QUIC-фейк + autottl=2 + cutoff=n3 (был рабочий)
echo   14. fake + QUIC-фейк + autottl=2 + cutoff=n2 (из general.bat)
echo:
echo   0. Выход
echo:
set /p "choice=Выбери вариант (0-14 или A): "

if /i "%choice%"=="0" exit /b
if /i "%choice%"=="A" goto stratA
if "%choice%"=="1" goto strat1
if "%choice%"=="2" goto strat2
if "%choice%"=="3" goto strat3
if "%choice%"=="4" goto strat4
if "%choice%"=="5" goto strat5
if "%choice%"=="6" goto strat6
if "%choice%"=="7" goto strat7
if "%choice%"=="8" goto strat8
if "%choice%"=="9" goto strat9
if "%choice%"=="10" goto strat10
if "%choice%"=="11" goto strat11
if "%choice%"=="12" goto strat12
if "%choice%"=="13" goto strat13
if "%choice%"=="14" goto strat14

echo Неверный выбор
echo:
pause
goto menu

:: ===================================================================
:: A. Диагностика — без desync, только перехват и проброс
:: Если с этим не работает — проблема НЕ в DPI (VPN/фаервол/версия)
:: ===================================================================
:stratA
echo:
echo [A] Без desync — чистый passthrough (WinDivert только перехватывает)
echo     Если НЕ подключается — проблема не в DPI, а в блокировке IP/фаерволе
cd /d %BIN%
start "zapret: test-gameserver #A" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-repeats=1 --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n1 --dpi-desync-fake-unknown-udp=0x00
goto done

:: ===================================================================
:: B. IP-фрагментация — принципиально другой механизм
:: DPI не может собрать фрагментированные IP-пакеты
:: ===================================================================
:strat1
echo:
echo [1] ipfrag2 — фрагментация IP-пакета (pos=8, по умолчанию)
cd /d %BIN%
start "zapret: test-gameserver #1" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=ipfrag2 --dpi-desync-any-protocol=1 --dpi-desync-ipfrag-pos-udp=8 --dpi-desync-cutoff=n3
goto done

:strat2
echo:
echo [2] ipfrag2 — фрагментация IP-пакета (pos=24, крупнее первый фрагмент)
cd /d %BIN%
start "zapret: test-gameserver #2" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=ipfrag2 --dpi-desync-any-protocol=1 --dpi-desync-ipfrag-pos-udp=24 --dpi-desync-cutoff=n3
goto done

:strat3
echo:
echo [3] fake + ipfrag2 — комбинация: фейк-пакет + фрагментация реального
cd /d %BIN%
start "zapret: test-gameserver #3" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake,ipfrag2 --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-ipfrag-pos-udp=8 --dpi-desync-cutoff=n3
goto done

:: ===================================================================
:: C. UDP length — изменение длины пакета
:: Ломает DPI, которая фингерпринтит размеры UDP-пакетов
:: ВАЖНО: если игра проверяет длину пакета, соединение сломается
:: ===================================================================
:strat4
echo:
echo [4] udplen — увеличение длины UDP на 2 байта
cd /d %BIN%
start "zapret: test-gameserver #4" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=udplen --dpi-desync-any-protocol=1 --dpi-desync-udplen-increment=2 --dpi-desync-cutoff=n3
goto done

:strat5
echo:
echo [5] udplen — увеличение длины UDP на 8 байт
cd /d %BIN%
start "zapret: test-gameserver #5" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=udplen --dpi-desync-any-protocol=1 --dpi-desync-udplen-increment=8 --dpi-desync-cutoff=n3
goto done

:strat6
echo:
echo [6] fake + udplen — комбинация: фейк-пакет + изменение длины
cd /d %BIN%
start "zapret: test-gameserver #6" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake,udplen --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-udplen-increment=4 --dpi-desync-cutoff=n3
goto done

:: ===================================================================
:: D. Fake с новыми параметрами, которые ранее не пробовались
:: ===================================================================
:strat7
echo:
echo [7] fake + badsum fooling + autottl=2 + cutoff=n1
echo     Фейк с битой контрольной суммой — сервер отбросит, DPI обработает
cd /d %BIN%
start "zapret: test-gameserver #7" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-fooling=badsum --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n1
goto done

:strat8
echo:
echo [8] fake + autottl=1 (минимальный delta) + cutoff=n1
echo     Фейк дойдёт до DPI но умрёт на 1 хоп дальше
cd /d %BIN%
start "zapret: test-gameserver #8" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=1 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n1
goto done

:strat9
echo:
echo [9] fake + stun.bin как фейк (другой payload) + autottl=2 + cutoff=n2
cd /d %BIN%
start "zapret: test-gameserver #9" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%stun.bin" --dpi-desync-cutoff=n2
goto done

:: ===================================================================
:: E. Агрессивные комбинации
:: ===================================================================
:strat10
echo:
echo [10] fake + repeats=24 (двойная доза фейков) + autottl=2 + cutoff=n2
cd /d %BIN%
start "zapret: test-gameserver #10" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=24 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n2
goto done

:strat11
echo:
echo [11] fake + autottl=2 + cutoff=d200 (остановить desync после 200 байт данных)
cd /d %BIN%
start "zapret: test-gameserver #11" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=d200
goto done

:strat12
echo:
echo [12] fake + autottl=2 + cutoff=s1 (остановить desync через 1 секунду)
cd /d %BIN%
start "zapret: test-gameserver #12" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=s1
goto done

:: ===================================================================
:: F. Старые рабочие стратегии (для сравнения и контроля)
:: ===================================================================
:strat13
echo:
echo [13] fake + QUIC-фейк + autottl=2 + cutoff=n3 (был рабочий ранее)
cd /d %BIN%
start "zapret: test-gameserver #13" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n3
goto done

:strat14
echo:
echo [14] fake + QUIC-фейк + autottl=2 + cutoff=n2 (из general.bat)
cd /d %BIN%
start "zapret: test-gameserver #14" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n2
goto done

:done
echo:
echo ================================================================
echo   Запущено. Проверь подключение к серверу.
echo   Чтобы остановить:  taskkill /f /im winws.exe
echo   Или закрой окно winws.
echo ================================================================
echo:
pause
goto menu
