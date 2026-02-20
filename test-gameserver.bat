@echo off
chcp 65001 > nul
:: Тестовый файл для подбора desync-стратегии для игрового сервера (UDP 2302-2303)
:: Запускает ТОЛЬКО фильтр для игровых портов — минимальный winws для быстрого тестирования

cd /d "%~dp0"

set "BIN=%~dp0bin\"
set "LISTS=%~dp0lists\"

:menu
echo ============================================================
echo   Тест desync-стратегий для игрового сервера (UDP 2302-2303)
echo ============================================================
echo:
echo   1. fake + QUIC-фейк + autottl=2 + cutoff=n3  (текущий)
echo   2. fake + нулевой фейк (0x00) + autottl=2 + cutoff=n3
echo   3. fake + QUIC-фейк + autottl=5 + cutoff=n5
echo   4. fake,udplen + QUIC-фейк + autottl=2 + cutoff=n3
echo   5. fake + QUIC-фейк + ttl=5 (фиксированный) + cutoff=n3
echo   6. fake + QUIC-фейк + autottl=2 + без cutoff
echo:
echo   0. Выход
echo:
set /p "choice=Выбери вариант (0-6): "

if "%choice%"=="0" exit /b
if "%choice%"=="1" goto strat1
if "%choice%"=="2" goto strat2
if "%choice%"=="3" goto strat3
if "%choice%"=="4" goto strat4
if "%choice%"=="5" goto strat5
if "%choice%"=="6" goto strat6

echo Неверный выбор
echo:
goto menu

:strat1
echo:
echo [Стратегия 1] fake + QUIC-фейк + autottl=2 + cutoff=n3
cd /d %BIN%
start "zapret: test-gameserver #1" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n3
goto done

:strat2
echo:
echo [Стратегия 2] fake + нулевой фейк (0x00) + autottl=2 + cutoff=n3
cd /d %BIN%
start "zapret: test-gameserver #2" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp=0x00000000000000000000000000000000000000000000000000000000000000000000000000000000 --dpi-desync-cutoff=n3
goto done

:strat3
echo:
echo [Стратегия 3] fake + QUIC-фейк + autottl=5 + cutoff=n5
cd /d %BIN%
start "zapret: test-gameserver #3" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=5 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n5
goto done

:strat4
echo:
echo [Стратегия 4] fake,udplen + QUIC-фейк + autottl=2 + cutoff=n3
cd /d %BIN%
start "zapret: test-gameserver #4" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake,udplen --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n3
goto done

:strat5
echo:
echo [Стратегия 5] fake + QUIC-фейк + ttl=5 (фиксированный) + cutoff=n3
cd /d %BIN%
start "zapret: test-gameserver #5" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-ttl=5 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin" --dpi-desync-cutoff=n3
goto done

:strat6
echo:
echo [Стратегия 6] fake + QUIC-фейк + autottl=2 + без cutoff
cd /d %BIN%
start "zapret: test-gameserver #6" /min "%BIN%winws.exe" --wf-udp=2302,2303 ^
--filter-udp=2302,2303 --ipset="%LISTS%ipset-all.txt" --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=12 --dpi-desync-any-protocol=1 --dpi-desync-fake-unknown-udp="%BIN%quic_initial_www_google_com.bin"
goto done

:done
echo:
echo Запущено. Проверь подключение к серверу.
echo Чтобы остановить — закрой окно winws или нажми Ctrl+C.
echo:
pause
