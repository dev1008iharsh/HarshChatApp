# 📱 HarshChat: Premium Real-Time Messaging Suite
### Ultra-Modern iOS Engine Built with Swift, Programmatic UIKit & MVVM
 
 
## 🎯 The Vision
**HarshChat** is not just a chat app; it is a showcase of high-end iOS engineering. Built specifically for users who demand a fluid, lag-free experience, it leverages **Firebase Realtime Database** for sub-second synchronization and **Programmatic UIKit** for a design that is as fast as it is beautiful.

---

## ✨ Elite UI & Advanced Animations
This project pushes the boundaries of `UIView.animate` and `CoreAnimation` to create a "living" interface.

* **Elastic OTP Transitions:** A custom spring-damping animation that slides the OTP container into view with a damping ratio, creating a physical "bounce" effect.
* **Floating Vector Dynamics:** The main login visual features a continuous floating animation combined with a sophisticated popup transition on `viewDidAppear`.
* **Interactive Pulse Effects:** The Floating Action Button (FAB) uses a recursive scaling animation to create a "heartbeat" pulse, drawing user attention to primary actions.
* **Fluid State Shifts:** Action buttons utilize `UIView.transition` with cross-dissolve to shift colors from Neutral Gray to Brand Green instantly as validation requirements are met.

---

## 🚀 Key Feature Deep-Dive

### 🔐 1. Next-Gen Authentication Flow
* **Smart Focus Management:** The UI automatically handles the transition between phone input and OTP, calling `becomeFirstResponder()` at the precise micro-second the animation ends.
* **Sticky Keyboard Logic:** A custom `KeyboardObserver` maintains a dynamic `UIScrollView` offset, ensuring the action button remains perfectly pinned above the keyboard across all iPhone screen sizes.

### 💬 2. High-Velocity Messaging
* **Realtime Database Sync:** Engineered for speed. Messages are synced instantly across devices with zero refresh lag.
* **Media Optimization:** Integrated **Kingfisher** for image processing and **JPEG compression** for lightning-fast photo sharing via Camera or Photo Library.
* **Deep-Zoom Gallery:** A custom-built `ImageViewerManager` that allows users to tap and expand images with full pinch-to-zoom gestures.

### 🔍 3. Intelligent Discovery
* **Live Contact Filtering:** Real-time search using `UISearchController` that filters through active conversations with $O(n)$ efficiency.
* **SMS Bridge:** Automated logic to detect non-registered contacts and trigger the `MFMessageComposeViewController` for seamless app invites.

### ⚙️ 4. Adaptive Profile Management
* **Live Data Sync:** The `SettingsViewModel` acts as a reactive bridge. Update your Bio or Profile Picture on one screen, and see it reflected everywhere in the app instantly.
* **Modern List Architecture:** Built using `UIListContentConfiguration` for a clean, iOS-native look that supports both Light and Dark modes perfectly.

---

## 🛠 Technical Stack & Engineering

### 🏗 MVVM Architecture
The project is strictly decoupled to ensure zero "Massive View Controller" issues:
* **Model:** Decodable structures for Firebase nodes.
* **View:** 100% Programmatic (No Storyboards/XIBs).
* **ViewModel:** Handles all Firebase logic, data validation, and error state mapping.

### 🧠 Performance & Memory Standards
* **Zero Leak Policy:** Strict use of `[weak self]` in all closure-based communication and Firebase observers.
* **Atomic Operations:** Conversation deletions are handled via `WriteBatch` logic to ensure all child messages are wiped simultaneously, preventing data bloating.

### 📊 Tech Summary
| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Database** | Firebase Realtime DB | For ultra-low latency message synchronization. |
| **Image Handling** | Kingfisher | Asynchronous downloading and aggressive caching. |
| **Animations** | Core Animation | Custom spring damping and transform-based transitions. |
| **Layout** | Programmatic Auto Layout | Precise UI control with zero Storyboard overhead. |
| **Architecture** | MVVM | Clean separation of business logic and UI. |

---

## 📸 Interface Preview

  

| Authentication | Chat Experience | Profile Settings |
| :---: | :---: | :---: |
| ✨ Fluid OTP Slide | 💬 Live Sync | ⚙️ Real-time Updates |

---

## 🏁 Getting Started
1. Clone the repo.
2. Add your `GoogleService-Info.plist` to the project root.
3. Open `HarshChat.xcodeproj`.
4. Build and Run on iOS 17.0+.

---

## 👨‍💻 Developed By

**Harsh** *Senior iOS Developer | Clean Architecture & Animation Specialist*

> *📧 **Email:** [dev.iharsh1008@gmail.com](mailto:dev.iharsh1008@gmail.com)*
> *📱 **Phone:** +91 9662108047*
> *🌐 **Portfolio:** [https://dev1008iharsh.github.io/](https://dev1008iharsh.github.io/)*
> *💼 **LinkedIn:** [https://www.linkedin.com/in/dev1008iharsh/](https://www.linkedin.com/in/dev1008iharsh/)*
> *🐙 **GitHub Repositories:** [https://github.com/dev1008iharsh?tab=repositories](https://github.com/dev1008iharsh?tab=repositories)*

---
