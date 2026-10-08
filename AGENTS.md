# AGENTS.md — DevFramework (Cursor + Grok)
<!-- DEVFRAMEWORK:MANAGED -->

Этот файл читается Cursor автоматически: и редактором, и CLI `agent`.
Рабочий агент — Cursor Agent. Модель по умолчанию — Grok `grok-4.7`.
Другую модель Grok можно задать через `FRAMEWORK_CURSOR_MODEL` (или `CURSOR_MODEL`).

## Запуск
Запускай агента через локальный лаунчер проекта (он сам выбирает Grok):

```
./cursor
```

Перед первым запуском установи CLI и войди в аккаунт:

```
curl https://cursor.com/install -fsS | bash
agent login
```

Для неинтерактивных задач оркестратора достаточно `CURSOR_API_KEY`.

## Триггеры
- "start" / "начать" / "begin" — выполнить стартовый протокол.

## Стартовый протокол
1) Если есть `framework/logs/discovery.pause`, продолжай интервью:
   - прочитай `framework/docs/discovery/interview.md`,
   - закрой только незаполненные вопросы,
   - после возобновления удали pause‑маркер.
2) Определи, есть ли legacy‑код в корне проекта:
   - считать legacy, если есть файлы/папки кроме: `framework/`, `framework.zip`,
     `install-fr.sh`, `install-fr-<version>.sh`, `.git/`, `.gitignore`, `AGENTS.md`,
     `AGENTS.override.md`, `.cursor/`, `cursor`, `.DS_Store`.
   - если legacy найден, запусти анализ:
     `FRAMEWORK_AGENT_FLOW=1 FRAMEWORK_SKIP_DISCOVERY=1 python3 framework/tools/run-protocol.py`
3) Запусти discovery интервью:
   - прочитай `framework/tasks/discovery.md` и следуй инструкциям;
   - задавай строго один вопрос за раз (без списков и батчей вопросов);
   - веди протокол `framework/docs/discovery/interview.md`;
   - веди транскрипт в `framework/logs/discovery.transcript.log` (append, с тайм‑метками).
4) После интервью сгенерируй артефакты:
   - `python3 framework/tools/generate-artifacts.py --overwrite`
5) В конце спроси: **«Можно ли начинать разработку?»**
   - если да: `python3 framework/orchestrator/orchestrator.py --phase main`.

## Пауза
Если пользователь вводит `/pause`:
- зафиксируй прогресс в `framework/docs/discovery/interview.md`,
- запиши `framework/logs/discovery.pause` (время + причина),
- корректно заверши сессию.

## Ограничения
- Не изменяй исходный код продукта во время discovery; работай только в `framework/docs`, `framework/logs`, `framework/migration`, `framework/review`.
- Не переключай модель. Оркестратор и `./cursor` уже передают `--model`.
