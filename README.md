# pnpios
Projekt PNPiOS_26

## Opis projektu

Projekt składa się z dwóch części:

1. backendu w Spring Boot
2. aplikacji mobilnej we Flutterze

Aplikacja mobilna komunikuje się wyłącznie z autorskim backendem REST, który udostępnia dane o książkach, autorach i walutach.

## Wymagania

### Backend
- Java 17 lub nowsza
- Maven
- plik `pom.xml`

### Frontend
- Flutter SDK
- Android Studio lub Visual Studio Code z obsługą Fluttera
- emulator Android albo urządzenie fizyczne
- plik `pubspec.yaml`

## Struktura projektu

Projekt zawiera dwie główne części:

- backend Spring Boot
- frontend Flutter

Kod backendu znajduje się w katalogu `src`.
Kod frontendu znajduje się w katalogu `lib`.

## Konfiguracja adresu backendu we Flutterze

Przed uruchomieniem frontendu należy sprawdzić, jaki adres backendu jest ustawiony w aplikacji Flutter.

Najczęściej znajduje się on w pliku podobnym do:

```text
lib/core/api_config.dart
```

Przykład konfiguracji:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080';
}
```

### Jaki adres ustawić

#### Emulator Android
Użyj:

```text
http://10.0.2.2:8080
```

#### Flutter uruchamiany na desktopie
Użyj:

```text
http://localhost:8080
```

#### Telefon fizyczny
Użyj lokalnego adresu IP komputera, na przykład:

```text
http://192.168.1.10:8080
```

## Uruchomienie backendu

### Krok 1. Otwórz terminal w katalogu backendu

Przejdź do katalogu, w którym znajduje się plik `pom.xml`.

### Krok 2. Uruchom backend

Wykonaj polecenie:

```bash
mvn spring-boot:run
```

### Krok 3. Sprawdź, czy backend działa

Po uruchomieniu backend powinien działać domyślnie pod adresem:

```text
http://localhost:8080
```

Możesz sprawdzić przykładowe endpointy:

```text
http://localhost:8080/api/v1/books/search?q=harry&page=0&size=10&currency=PLN
http://localhost:8080/api/v1/authors/search?q=rowling&page=0&size=10
http://localhost:8080/api/v1/currencies?base=PLN
```

Jeżeli backend działa poprawnie, powinieneś zobaczyć odpowiedź JSON.

## Uruchomienie frontendu Flutter

### Krok 1. Otwórz terminal w katalogu frontendu

Przejdź do katalogu, w którym znajduje się plik `pubspec.yaml`.

### Krok 2. Pobierz zależności

Wykonaj:

```bash
flutter pub get
```

### Krok 3. Sprawdź dostępne urządzenia

Wykonaj:

```bash
flutter devices
```

### Krok 4. Uruchom emulator albo podłącz urządzenie

Uruchom emulator Android w Android Studio albo podłącz fizyczne urządzenie.

### Krok 5. Uruchom aplikację

Wykonaj:

```bash
flutter run
```

## Zalecana kolejność uruchamiania projektu

1. uruchom backend Spring Boot
2. sprawdź, czy backend działa na porcie `8080`
3. ustaw poprawny adres backendu w aplikacji Flutter
4. pobierz zależności Fluttera
5. uruchom emulator albo podłącz urządzenie
6. uruchom frontend

## Najczęstsze problemy

### Frontend nie łączy się z backendem

Sprawdź:
- czy backend działa
- czy adres backendu w Flutterze jest poprawny
- czy na emulatorze Android używasz `10.0.2.2`, a nie `localhost`
- czy port `8080` nie jest zajęty lub zablokowany

### Flutter zgłasza błąd zależności

Wykonaj:

```bash
flutter clean
flutter pub get
```

### Backend nie uruchamia się przez Maven

Sprawdź:
- czy Java jest zainstalowana
- czy Maven jest zainstalowany
- czy zmienna `JAVA_HOME` jest ustawiona poprawnie
- czy plik `pom.xml` jest poprawny

### Aplikacja uruchamia się, ale nie wyświetla danych

Sprawdź:
- czy backend zwraca odpowiedzi JSON
- czy frontend ma poprawny `baseUrl`
- czy backend nie zwraca błędów 400, 404 lub 500
- czy frontend i backend są uruchomione na właściwych adresach

## Szybki start

### Backend

```bash
mvn spring-boot:run
```

### Frontend

```bash
flutter pub get
flutter run
```

## Funkcjonalności projektu

Projekt obejmuje między innymi:
- wyszukiwanie książek
- wyszukiwanie autorów
- podgląd szczegółów książki
- podgląd szczegółów autora
- pobieranie listy walut
- zapisane książki i autorów
- ustawienia aplikacji
- komunikację z własnym backendem REST

## Problem z certyfikatami

Jeżeli backend nie może pobrać kursów z np. NBP i w logach pojawia się błąd podobny do:

```text
PKIX path building failed
unable to find valid certification path to requested target
SSLHandshakeException
```

to oznacza, że Java uruchamiająca backend nie ufa certyfikatowi używanemu między innymi przez `https://api.nbp.pl`.

W tej sytuacji nie trzeba generować własnych certyfikatów. Wystarczy dodać odpowiednie certyfikaty Certum do truststore Javy.

### Objawy

Backend próbuje wykonać request:

```text
GET https://api.nbp.pl/api/exchangerates/tables/A?format=json
```

ale połączenie kończy się błędem TLS jeszcze przed odebraniem odpowiedzi HTTP.

### Przyczyna

Z logów handshake wynika, że serwer NBP odsyła łańcuch certyfikatów oparty o:

- `CN=*.nbp.pl`
- `CN=Certum OV TLS G2 R39 CA`
- `CN=Certum Trusted Root CA`

Jeżeli Java nie ma zaufania do tego root/intermediate, pojawia się błąd `PKIX path building failed`.

### Instrukcja naprawy

#### 1. Pobranie certyfikatów

Uruchom PowerShell i wykonaj:

```powershell
New-Item -ItemType Directory -Force C:\temp\certum | Out-Null

Invoke-WebRequest -Uri "http://subca.repository.certum.pl/ctrca.cer" -OutFile "C:\temp\certum\certum-root.cer"
Invoke-WebRequest -Uri "http://certumovtlsg2r39ca.repository.certum.pl/certumovtlsg2r39ca.cer" -OutFile "C:\temp\certum\certum-r39-intermediate.cer"
```

Po wykonaniu tych poleceń powinny istnieć pliki:

- `C:\temp\certum\certum-root.cer`
- `C:\temp\certum\certum-r39-intermediate.cer`

---

#### 2. Import certyfikatów do Javy używanej przez backend

Backend uruchamiany jest z:

```text
C:\Program Files\Java\jdk-24\bin\java.exe
```

więc należy dodać certyfikaty do truststore tej właśnie Javy:

```text
C:\Program Files\Java\jdk-24\lib\security\cacerts
```

Uruchom terminal **jako administrator** i wykonaj:

```powershell
& "C:\Program Files\Java\jdk-24\bin\keytool.exe" -importcert -noprompt -alias certum-trusted-root-ca -file "C:\temp\certum\certum-root.cer" -keystore "C:\Program Files\Java\jdk-24\lib\security\cacerts" -storepass changeit

& "C:\Program Files\Java\jdk-24\bin\keytool.exe" -importcert -noprompt -alias certum-ov-tls-g2-r39-ca -file "C:\temp\certum\certum-r39-intermediate.cer" -keystore "C:\Program Files\Java\jdk-24\lib\security\cacerts" -storepass changeit
```

---

#### 3. Sprawdzenie, czy import się powiódł

Wykonaj:

```powershell
& "C:\Program Files\Java\jdk-24\bin\keytool.exe" -list -keystore "C:\Program Files\Java\jdk-24\lib\security\cacerts" -storepass changeit | findstr /I certum
```

Wynik powinien zawierać wpisy podobne do:

- `certum-trusted-root-ca`
- `certum-ov-tls-g2-r39-ca`

---

### Dodatkowa uwaga

Fallback lokalny można zostawić w projekcie jako zabezpieczenie na wypadek:
- chwilowego braku dostępu do NBP,
- problemów sieciowych,
- niedostępności zewnętrznego API.

Nie zastępuje on jednak poprawnej konfiguracji certyfikatów, jeśli projekt ma pobierać kursy z NBP na żywo.

---

### Szybka lista kroków

1. Pobierz certyfikaty Certum.
2. Zaimportuj je do `cacerts` w `jdk-24`.
3. Sprawdź, czy aliasy są widoczne.
4. Usuń zbędne VM options TLS.
5. Uruchom backend ponownie.

# Uruchamianie testów w projekcie PNPiOS 26

Ten plik opisuje uruchamianie testów dodanych do aktualnej wersji projektu. W projekcie wymagane są dwa typy testów:

- testy jednostkowe backendu,
- testy jednostkowe oraz UI/widget tests frontendu.

## 1. Testy backendu

Testy backendu znajdują się w katalogu:

```text
backend/pnpios/src/test/java
```

Dodane testy powinny znajdować się między innymi w:

```text
src/test/java/pl/pg/pnpios/services/CurrencyServiceTest.java
src/test/java/pl/pg/pnpios/services/OfferAggregationServiceTest.java
```

### Uruchomienie wszystkich testów backendu

Wejdź do katalogu backendu, czyli tam, gdzie znajduje się plik `pom.xml`:

```bash
cd backend/pnpios
mvn test
```

Jeżeli projekt używa Maven Wrappera, można użyć:

Windows:

```bash
cd backend/pnpios
.\mvnw test
```

Linux/macOS:

```bash
cd backend/pnpios
./mvnw test
```

### Uruchomienie pojedynczej klasy testowej backendu

```bash
mvn -Dtest=CurrencyServiceTest test
```

```bash
mvn -Dtest=OfferAggregationServiceTest test
```

### Wyniki testów backendu

Po uruchomieniu testów Maven zapisuje raporty w katalogu:

```text
target/surefire-reports
```

Jeżeli testy nie startują, należy sprawdzić, czy w `pom.xml` znajduje się zależność testowa Spring Boot:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

## 2. Testy frontendu

Testy frontendu znajdują się w katalogu:

```text
frontend/test
```

Dodane testy powinny znajdować się między innymi w:

```text
test/models/app_models_test.dart
test/services/local_storage_service_test.dart
test/screens/books_screen_test.dart
```

W projekcie frontendu są używane dwa typy testów:

- testy jednostkowe modeli i usług,
- testy UI/widget tests dla ekranu wyszukiwania książek.

### Pobranie zależności frontendu

Wejdź do katalogu frontendu, czyli tam, gdzie znajduje się plik `pubspec.yaml`:

```bash
cd frontend
flutter pub get
```

Jeżeli projekt Flutter znajduje się w innym podkatalogu, trzeba wejść dokładnie do tego katalogu, który zawiera `pubspec.yaml`.

### Uruchomienie wszystkich testów frontendu

```bash
flutter test
```

### Uruchomienie pojedynczych testów frontendu

Testy modeli:

```bash
flutter test test/models/app_models_test.dart
```

Testy lokalnego zapisu, historii wyszukiwania i ustawień:

```bash
flutter test test/services/local_storage_service_test.dart
```

Test UI ekranu książek:

```bash
flutter test test/screens/books_screen_test.dart
```

### Raport pokrycia testów frontendu

Opcjonalnie można uruchomić testy z raportem pokrycia:

```bash
flutter test --coverage
```

Raport zostanie zapisany w:

```text
coverage/lcov.info
```

## 3. Co sprawdzają testy

### Backend

Testy backendu sprawdzają między innymi:

- przeliczanie walut na podstawie kursów zwracanych przez backend,
- obsługę cache kursów walut,
- sortowanie ofert po cenie,
- filtrowanie ofert po źródle,
- deduplikację ofert,
- wyliczanie zakresu cen.

### Frontend

Testy frontendu sprawdzają między innymi:

- poprawne mapowanie odpowiedzi JSON na modele aplikacji,
- zapis i odczyt lokalnych ustawień,
- historię wyszukiwania,
- limit historii wyszukiwania,
- brak osobnego przycisku „Szukaj” przy pasku wyszukiwania,
- obecność przycisków historii i filtrów,
- wyszukiwanie po zatwierdzeniu pola tekstowego,
- podstawowe działanie filtrowania wyników.

## 4. Kolejność sprawdzania przed oddaniem projektu

Najbezpieczniej uruchomić komendy w tej kolejności:

```bash
cd backend/pnpios
mvn test
```

Następnie:

```bash
cd frontend
flutter pub get
flutter test
```

Jeżeli oba polecenia kończą się bez błędów, projekt spełnia wymaganie dodania testów jednostkowych oraz testów UI/widget tests.
