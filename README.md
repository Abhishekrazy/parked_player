# 🚗 Parked Player - Android Auto Video Streamer

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) 
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**Parked Player** is a specialized video streaming application designed specifically for **Android Auto**. It allows users to stream content from popular platforms like YouTube, Vimeo, and more, but with a critical safety focus: it is designed to function only when the vehicle is in **Parked Mode**.

---

## 💡 The Inspiration
Hi, I'm **Abhishek Razy**. 

One day, while waiting in my car, I realized a major gap in the Android Auto ecosystem: there are almost no official video players that allow you to enjoy content while you're parked. Whether you're waiting for a charge, a friend, or just taking a break, your car's screen remains largely underutilized for entertainment.

I thought, *"Why isn't there a simple way to watch my favorite streams safely?"* That's when I decided to build **Parked Player** myself—a bridge between your favorite web content and your car's infotainment system.

---

## 🛠️ Technologies Used

- **Flutter & Dart**: For a high-performance, responsive cross-platform UI.
- **Android Auto Car App Library**: To integrate deeply with the automotive environment and ensure compliance with parked-state requirements.
- **WebView Flutter**: To provide a seamless browsing and viewing experience for web-based video platforms.
- **Logo.dev API**: For dynamic high-quality favicon and logo fetching for your custom added sites.
- **Provider**: For robust state management across the app.

---

## ✨ Features

- **Parked Mode Exclusive**: Designed to comply with safety standards by focusing on the parked experience.
- **Multi-Platform Support**: YouTube, Vimeo, Twitch, and more ready out of the box.
- **Custom Apps**: Add your own favorite streaming URLs with automatic logo fetching.
- **Incognito Mode**: Browse and watch without saving history locally.
- **Premium UI**: Sleek, dark-mode focused design with glassmorphic elements and smooth animations.

---

## 🚀 Getting Started

To run this project locally, you'll need the Flutter SDK and an Android device/emulator with Android Auto support.

### 1. Clone the repository
```bash
git clone https://github.com/Abhishekrazy/parked_player.git
cd parked_player
```

### 2. Configure Local Environment
Since this project uses the Logo.dev API, you'll need a token. We use a safe configuration method:
- Create a `local_env.json` file in the root directory.
- Use the template provided in `local_env.json.template`.
- Run the app using:
```bash
flutter run --dart-define-from-file=local_env.json
```

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👋 Connect with Me

- **Portfolio**: [abhishekrazy.com](https://abhishekrazy.com)
- **GitHub**: [@Abhishekrazy](https://github.com/Abhishekrazy)

*Safe driving! Only use this app when your vehicle is safely parked.*
