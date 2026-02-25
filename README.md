<p align="center">
  <img width="150" height="150" alt="Group 2@1x" src="https://github.com/user-attachments/assets/084ac1a1-5247-4c18-9023-e2b266b6357d" />
</p>

# RViewer - StackOverflow Client for Discovering Developers and Questions

iOS app built for a test assignment.

Because Reddit API access was rejected, this implementation uses **Stack Exchange API (Stack Overflow)** with equivalent flows:
- top users list;
- posts list and post details;
- user search;
- user details.

## Assignment Notes

- Original assignment requested Reddit API;
- Current implementation maps required behavior to Stack Overflow endpoints;
- Architecture and UX goals from the assignment are preserved.

## Features

- **Top Users tab**
  - Loads popular Stack Overflow users by reputation;
  - Pull-to-refresh;
  - Infinite scrolling (pagination);
  - Error handling with alert.

<img width="290" height="629" alt="Screenshot 2026-02-25 at 11 56 17" src="https://github.com/user-attachments/assets/2f3bda96-236a-409f-8bd0-4dc9b59615bf" />
<img width="290" height="629" alt="Screenshot 2026-02-25 at 11 56 29" src="https://github.com/user-attachments/assets/e153dbb9-101d-480a-8115-b0e8edcdc890" />
<br><br>

- **Posts tab**
  - Loads recent Stack Overflow questions;
  - Pull-to-refresh;
  - Infinite scrolling (pagination);
  - Open post details screen.

<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 08 39" src="https://github.com/user-attachments/assets/dff16da2-8500-4492-946e-db9d75590067" />
<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 09 59" src="https://github.com/user-attachments/assets/85d4e34f-c275-49bf-aac5-e0aa53181fae" />
<br><br>

- **Post Details**
  - Shows title, stats, tags, parsed body text;
  - Open question in Safari;
  - Open the author profile in `UserInfoVC`.

<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 01 06" src="https://github.com/user-attachments/assets/3cbd4453-4fdb-426b-b030-deea488adc16" />
<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 01 12" src="https://github.com/user-attachments/assets/54d89031-f876-45b0-a4f9-7d6b290fa153" />
<br><br>

- **Search tab**
  - Search users by name;
  - 1-second debounce to avoid calling the API too frequently;
  - Minimum query length: 2;
  - Empty states and cancel behavior.

<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 01 48" src="https://github.com/user-attachments/assets/c28a8818-f572-43e1-9652-f9b1ee6eb796" />
<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 02 14" src="https://github.com/user-attachments/assets/37e0c911-223a-40c3-929d-c6b61d28ab26" />
<br><br>

- **Saved tab**
  - Persist users locally with Realm;
  - Swipe to remove saved users;
  - Open saved user details.

<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 02 57" src="https://github.com/user-attachments/assets/b2cb5b60-0499-4bf9-8823-102220bd2eba" />
<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 12 02 40" src="https://github.com/user-attachments/assets/f380cd4b-c694-4552-bdef-c3083c29df0c" />
<br><br>

- **User Details**
  - Full user metadata;
  - Save/remove user from local database;
  - Long-press any row to copy value;
  - Long-press avatar to save image to Photos app.

<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 11 58 06" src="https://github.com/user-attachments/assets/d19bffd4-39aa-4c09-93e0-ac6d64ce564b" />
<img width="290" height="629" alt="Simulator Screenshot - iPhone 17 Pro - 2026-02-25 at 11 58 52" src="https://github.com/user-attachments/assets/e2b953cf-e342-43fd-bd43-e299e1603ff9" />
<br><br>

## Tech Stack

- `UIKit`;
- `SnapKit` (layout);
- `RealmSwift` (saved users);
- `KeychainWrapper` (secure storage for tokens);
- `Swift Concurrency` (`async/await`, `Task`);
- `Swift Testing` (unit tests).

## Architecture

Pragmatic MVVM with clear data boundaries:

- **ViewControllers**
  - Render UI and route user actions;
  - Bind to ViewModel callbacks.

- **ViewModels**
  - Contain screen logic/state;
  - Trigger repository calls;
  - Expose `onDataDidUpdate`, `onError`, etc.

- **Repositories**
  - `DefaultUsersRepository`;
  - `DefaultQuestionsRepository`;
  - Apply caching policy and API fallback strategy.

- **API clients**
  - `StackOverflowAPIClient`;
  - `StackOverflowQuestionsAPIClient`.

- **Dependency Composition**
  - `AppDependencies.live()` wires production graph in `SceneDelegate`.

## Network Endpoints

Used Stack Exchange endpoints:

- Users: `GET /2.3/users` (sorted by reputation);
- User search: `GET /2.3/users?inname=...`;
- Questions: `GET /2.3/questions` (sorted by activity, with body).

## Auth/Token Flow

The app obtains credentials from mock endpoint:
- `https://phxqik.mockapi.dog/`

Token handling:
- JWT cached in Keychain (`clientID.jwt`);
- API key extracted from JWT `token` claim;
- API key cached in Keychain (`clientID.token`);
- Retry logic on credential decode failure.

## Caching Strategy

`UsersResponseCache` and `QuestionsResponseCache` use:
- `NSCache` (in-memory fast path);
- JSON files in app `Caches` directory (disk fallback);
- TTL validation via `createdAt`.

Current TTL policy:
- Top users: `10 min`;
- User search: `5 min`;
- Questions/posts: `5 min`.

Behavior:
- Top users/posts: cache-first, then network;
- Search: network-first, fallback to cached result on failure.

## Persistence

Saved users are stored in Realm:
- Store: `SavedUsersStore`;
- Model: `SavedUserObject`;
- Mapper: `SavedUserMapper`.

Sort order: latest saved first (`savedAt` descending).

## Project Structure

Main folders:

- `RedditViewer/App` - app entry + dependency graph;
- `RedditViewer/Network` - requests, models, cache classes;
- `RedditViewer/ViewControllers` - UI screens + per-screen view models + Views/Cells;
- `RedditViewer/DB` - Realm models/store/mappers;
- `RedditViewer/Presentation` - formatting helpers;
- `RedditViewer/Helper` - Keychain utilities;
- `RedditViewerTests` - architecture and behavior tests.

## Requirements

- Xcode 16+;
- iOS 16+ simulator/device;
- Internet access for Stack Exchange + mock credentials endpoint.

## Build & Run

1. Open `RedditViewer.xcodeproj`;
2. Select scheme `RedditViewer`;
3. Run on iOS Simulator.

## Tests

Implemented tests cover:

- Repository caching behavior;
- ViewModel loading/pagination/cancel states;
- Cache save/load and expiration behavior.

Run from Xcode:
- `Product -> Test`.
