# Todo App

A Flutter Todo application built using **Clean Architecture**, **Riverpod**, **Retrofit**, and **Firebase Authentication**.

## Features

- User sign up and login with Firebase Authentication
- Create, update, delete todos
- View todo list
- Clean and scalable project structure
- State management using Riverpod
- API integration using Retrofit

## Tech Stack

- **Flutter**
- **Dart**
- **Riverpod**
- **Retrofit**
- **Firebase Auth**
- **Clean Architecture**

## Architecture

This project follows **Clean Architecture** for better scalability, maintainability, and testability.

### Layers

- **Presentation**
  - UI
  - Screens
  - Widgets
  - Riverpod providers

- **Domain**
  - Entities
  - Repository contracts
  - Use cases

- **Data**
  - Models
  - Repository implementations
  - Remote/local data sources

## Folder Structure

```bash
lib/
├── core/
├── features/
│   └── todo/
│       ├── data/
│       │   ├── datasource/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           └── widgets/
├── main.dart
