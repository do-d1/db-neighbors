# dB Neighbors — Flutter App

רשת חברתית לשכנים המבוססת על מדידת רעש בזמן אמת.

## פיצ'רים

- **מדידת dB** — מד רמת רעש חי עם סווג (שקט / רגיל / רועש)
- **מדידת BPM** — זיהוי קצב מהסביבה (מוזיקה, צעדים) ע"י autocorrelation
- **מהירות דיבור** — ספירת הברות + חישוב WPM בחלון 5 שניות
- **רשת חברתית** — חיבור שכנים ב-4 שיטות + צ'אט + התראות
- **4 שיטות חיבור שכן** — GPS, כתובת, QR code, קוד בניין

---

## דרישות מקדימות

1. Flutter 3.16+ — https://flutter.dev/docs/get-started/install
2. Android Studio / Xcode
3. חשבון Firebase — https://console.firebase.google.com

---

## התקנה

### 1. Firebase setup

```bash
# התקן Firebase CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# התחבר לחשבון
firebase login

# צור פרויקט Firebase חדש ב-console.firebase.google.com
# ואז הגדר את האפליקציה:
flutterfire configure
```

זה יוצר קובץ `lib/firebase_options.dart` אוטומטית.

**ב-Firebase Console, הפעל:**
- Authentication → Email/Password
- Firestore Database
- Cloud Messaging (FCM)

### 2. Firestore rules (Firebase Console → Firestore → Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users — read by all, write by owner
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Connections — read/write by participants
    match /connections/{connId} {
      allow read, write: if request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      
      match /messages/{msgId} {
        allow read, write: if request.auth.uid in 
          get(/databases/$(database)/documents/connections/$(connId)).data.participants;
      }
    }
    
    // Buildings
    match /buildings/{buildingId} {
      allow read: if request.auth != null;
    }
    
    // Measurements
    match /measurements/{measId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

### 3. הרץ את האפליקציה

```bash
cd db_neighbors
flutter pub get
flutter run
```

---

## מבנה הפרויקט

```
lib/
  main.dart                    # Entry point + theme
  services/
    audio_measurement_service.dart  # dB + BPM + speech speed
    auth_service.dart               # Firebase Auth + user profile
  screens/
    home_screen.dart           # Bottom nav shell
    measure_screen.dart        # Main measurement UI
    neighbors_screen.dart      # Social feed
    connect_neighbor_screen.dart    # 4 connection methods
    chat_screen.dart           # Neighbor chat
    history_screen.dart        # Charts + history
    settings_screen.dart       # Settings
    auth_screen.dart           # Login / register
  widgets/
    db_gauge.dart              # Circular dB meter
    bpm_widget.dart            # BPM + speech speed widgets
    room_selector.dart         # Room grid picker
  models/
    neighbor_model.dart        # NeighborConnection model
```

---

## כיצד עובדת מדידת BPM

האלגוריתם משתמש ב-**autocorrelation**:
1. אוסף חלון של 1024 דגימות מרמת האמפליטודה
2. מחשב מתאם עצמי (self-correlation) לתזוזות (lags) בין 20–200 דגימות
3. פיק במתאם = תקופתיות = BPM
4. ממיר: `BPM = 60 / (bestLag / sampleRate)`

**מה ניתן לזהות:** בס של מוזיקה, צעדים קצביים, מכונות חוזרות

---

## כיצד עובדת מהירות דיבור

1. **זיהוי דיבור** — רמת dB > 45 = "בתוך דיבור"
2. **ספירת הברות** — מזהה פיק אמפליטודה מעל 55 dB, ואחריו ירידה  
   → כל פיק כזה = הברה אחת
3. **חלון 5 שניות** — כל 5 שנ' מחשב:  
   `syllables_per_second = syllable_count / 5`  
   `WPM ≈ sps × 60 / 1.5` (ממוצע 1.5 הברות למילה בעברית)

---

## שיווק

האפליקציה מיועדת לשיווק לדיירי בניין:
- **אונבורדינג קל** — קוד בניין שמנהל הבית מחלק
- **ערך מיידי** — כל אחד רואה את הרעש שהוא מפיק
- **תמריץ חברתי** — שכן רואה ש-78 dB נמדד → מוריד ספונטנית

---

## TODO / שלבים הבאים

- [ ] מפת דירה ציורית (canvas-based floor plan)
- [ ] Push notifications כש-dB > threshold
- [ ] יצוא דוחות PDF
- [ ] Equalizer helper (מדידת תדרים)
- [ ] Apple Sign In
- [ ] Widget לאנדרויד (מד dB על מסך הבית)
