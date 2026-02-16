# Privacy Policy for Parked Player

**Effective Date: January 30, 2026**

Welcome to **Parked Player** ("the App", "we", "us", or "our"), an open-source video streaming utility designed specifically for use with Android Auto. Your privacy and the security of your data are of paramount importance to us. This Privacy Policy outlines exactly how we handle information, the measures we take to protect it, and the transparency we provide as an open-source project.

---

## 1. Introduction and Core Philosophy
Parked Player is built on a "Privacy-by-Design" philosophy. We believe that you should be able to enjoy your favorite video content in your vehicle without sacrificing your digital privacy. To that end, **Parked Player is a non-tracking, non-identifying application.**

## 2. Information Collection and Use

### A. Personal Data
We do **not** collect any Personal Identifiable Information (PII).
- We do not require account creation, logins, or social media integration.
- We do not ask for or store your name, email address, mailing address, or phone number.
- We do not access your device's contacts, calendar, or photos.

### B. Device and Vehicle Information
- **Parked Status:** To comply with automotive safety standards, the App requests access to the "Vehicle Parked Status" via the Android Auto API. This is used solely as a real-time logical switch to enable/disable the video player. This status is processed locally on the device and is **never** logged, stored, or transmitted to any external server.
- **Device Model & OS:** Standard anonymous device information (e.g., OS version) may be processed by the Flutter framework to ensure compatibility, but this is never linked to an individual user identity by us.

### C. Local Storage (On-Device Only)
The following data is stored exclusively on your device's local memory to provide a consistent user experience:
- **Site Preferences:** The list of streaming sites you have added, including their names and URLs.
- **Custom Site Metadata:** Local file paths for site logos fetched via external APIs.
- **User Interface Preferences:** Your choice between Grid/List view and Light/Dark themes.
- **Cached Content:** Minimal caching to improve the loading speed of site icons.

**Important:** This data is stored in the App's private directory and is deleted if you uninstall the App. We have no way of accessing this data remotely.

## 3. Third-Party Services and APIs

While Parked Player itself is private, it utilizes third-party components to provide functionality. These services have their own independent privacy policies:

### A. WebView Content (Streaming Platforms)
When you view a video, the App uses a system-standard **Android WebView**.
- Interaction with platforms like **YouTube, Vimeo, Twitch,** etc., occurs within this WebView.
- These third-party websites may use cookies, trackers, and other technologies to collect your browsing data as if you were using a standard mobile browser.
- We recommend reviewing the privacy policies of any website you visit through the App.

### B. Logo Fetching (Logo.dev)
To fetch high-quality icons for custom sites you add, the App communicates with the **Logo.dev API**.
- When you add a new site, the domain name (e.g., "netflix.com") is sent to Logo.dev to retrieve the corresponding logo.
- No personal user data is sent during this request—only the public domain name of the site you wish to add.

### C. GitHub Actions (CI/CD)
The App's source code is hosted on GitHub. While the App is running on your device, it does not communicate with GitHub. However, the build process for the APK/AAB files provided in the "Releases" section is managed by GitHub Actions.

## 4. Incognito Mode
The App provides an "Incognito Mode" to enhance your session privacy. When enabled:
- The App does not save new custom sites to your permanent local list.
- We attempt to instruct the system WebView to clear session data (though persistent tracking by the websites themselves may still occur).

## 5. Data Security
Because Parked Player is open-source, the community can audit our code to verify that no "hidden" data collection is taking place. We use standard Android security protocols to protect the limited data stored on your device.

## 6. Children's Privacy
Parked Player does not knowingly collect or solicit any information from anyone under the age of 13. The App is intended for use by licensed drivers in a parked vehicle environment.

## 7. International Data Transfers
Since no data is collected or stored on our servers, there are no international transfers of your personal data by us.

## 8. Compliance with Legal Requests
As we do not store your personal data, we cannot provide any user information to law enforcement or government agencies, as we do not possess it.

## 9. Updates to This Policy
We may update this Privacy Policy to reflect changes in the App's features or legal requirements. Any updates will be reflected by a change in the "Effective Date" at the top of this document. We encourage users to review the project's GitHub repository for the latest version.

## 10. Contact Information
If you have questions about this Privacy Policy or how your data is handled, please reach out to the project maintainer:

**Abhishek Razy**  
- **Website:** [abhishekrazy.com](https://abhishekrazy.com)
- **GitHub Repository:** [Abhishekrazy/parked_player](https://github.com/Abhishekrazy/parked_player)

---
*Disclaimer: This App is provided "as is" without warranty of any kind. Users are responsible for their own data privacy when interacting with third-party websites through the App's WebView.*
