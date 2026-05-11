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

## Uwagi końcowe

Backend musi być uruchomiony przed frontendem.
Frontend i backend muszą używać zgodnego adresu połączenia.
W przypadku emulatora Android należy używać `http://10.0.2.2:8080`.
