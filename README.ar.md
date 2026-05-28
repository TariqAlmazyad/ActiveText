<div dir="rtl">

# ActiveText

[English](README.md) · **العربية**

</div>

[![CI](https://github.com/TariqAlmazyad/ActiveText/actions/workflows/ci.yml/badge.svg)](https://github.com/TariqAlmazyad/ActiveText/actions/workflows/ci.yml)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg?logo=swift)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<div dir="rtl">

**بديل جاهز لِـ `Text` في SwiftUI يجعل الـ mentions والـ hashtags والروابط والبريد الإلكتروني وأرقام الهاتف قابلة للنقر — بسطرٍ واحد.**

بدون أي اعتماديات خارجية. Swift Package Manager فقط.

</div>

```swift
ActiveText("Hello @ActiveText")
    .detect([.mention])
    .color(.mention, .pink)
```

<img src="https://github.com/user-attachments/assets/ff93c061-9850-4add-87ba-6c36cd9d946d" width="900" alt="Detect mentions">

<div dir="rtl">

تلك هي الفكرة كاملة. تابِع للمزيد — كل قسم بالأسفل هو **مقطع واحد + النتيجة**.

---

## التثبيت

في Xcode: **File ▸ Add Package Dependencies…** ثم الصق:

</div>

```
https://github.com/TariqAlmazyad/ActiveText.git
```

<div dir="rtl">

أو داخل `Package.swift`:

</div>

```swift
.package(url: "https://github.com/TariqAlmazyad/ActiveText.git", from: "1.0.0")
```

<div dir="rtl">

ثم `import ActiveText`. يتطلب **iOS 17+** و **Swift 6 (Xcode 16+)**.

---

## أمثلة

### 1. اكتشاف كل شيء وتنسيق كل نوع

اختر ما تريد البحث عنه، ثم لوّنه كما يحلو لك.

</div>

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .underline(.mention)
    .underline([.phone, .hashtag])
```

<img src="https://github.com/user-attachments/assets/54b836b9-5fb5-4fce-86f8-99fa7d478c96" width="900" alt="Detect everything, custom colors">

<div dir="rtl">

### 2. التعامل مع النقرات

لكل نوع دالة استدعاء خاصة به. كما تُفتح الروابط والبريد والهاتف تلقائيًا (أوقِف ذلك بِـ `.autoOpenLinks(false)`).

</div>

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .onElementTap { textTapped in
        print(textTapped.type, textTapped.value)
    }
```

<img src="https://github.com/user-attachments/assets/0f5679c1-e335-49c7-8880-2ee1703617a4" width="900" alt="Tap handlers">

<div dir="rtl">

### 3. التسطير والتظليل

امزِج وطابِق حسب كل نوع.

</div>

```swift
ActiveText(text)
    .detect([.mention, .url, .email, .phone, .hashtag])
    .underline(.mention)
    .underline([.phone, .hashtag])
    .highlight(.hashtag, .green.opacity(0.4))
    .highlight(.mention, .red.opacity(0.4))
    .highlight(.url, .yellow.opacity(0.4))
```

<img src="https://github.com/user-attachments/assets/23b7c60d-a7df-40a4-98ab-0db204864a3a" width="900" alt="Underline & highlight">

<div dir="rtl">

### 4. أنماطك الخاصة

نوع regex مخصّص — مثالي لِـ معرّفات التذاكر، الـ SKUs، وأي شيء آخر.

</div>

```swift
ActiveText("See ticket TICKET-42")
    .detectCustom(id: "ticket", pattern: #"TICKET-\d+"#) { value in
        open(ticket: value)
    }
```

<img src="https://github.com/user-attachments/assets/bfca47be-e981-462e-99cb-173aef9a3151" width="900" alt="Custom pattern">

<div dir="rtl">

### 5. روابط Markdown

حوِّل صيغة `[label](url)` إلى رابط حقيقي قابل للنقر. مُعدِّل واحد.

**قبل — يظهر الـ Markdown الخام كما هو:**

</div>

<img src="https://github.com/user-attachments/assets/b3884db2-0f2b-44d7-aaff-06de555be3e4" width="900" alt="Markdown links — before">

<div dir="rtl">

**بعد — `.markdown()` يقوم بالمهمة:**

</div>

```swift
ActiveText(text)
    .markdown()
    .color(.url, .blue)
    .underline(.url)
```

<img src="https://github.com/user-attachments/assets/d695b2cf-e47a-4e97-8735-0bdbf950ada4" width="900" alt="Markdown links — after">

<div dir="rtl">

### 6. تحديد الأسطر والمحاذاة

يعمل تمامًا مثل `Text` في SwiftUI:

</div>

```swift
ActiveText(text).lineLimit(2)
ActiveText(text).multilineTextAlignment(.center)
```

<p>
  <img src="https://github.com/user-attachments/assets/71ce7736-469b-40a7-bddf-2874e30649ae" width="440" alt="Limit lines">
  <img src="https://github.com/user-attachments/assets/aabad6b2-238d-41c1-86ef-517f40d84498" width="440" alt="Alignment">
</p>

<div dir="rtl">

---

## قوائم الضغط المطوّل (Long-press menus)

اضغط مطوّلًا على أي عنصر مُكتشَف لتحصل على قائمة سياقية أصلية — نسخ، مشاركة، أو إجراءاتك الخاصة.

### القائمة الافتراضية

</div>

```swift
 ActiveText(text)
    .detect([.mention])
    .menuItems {
        Button {
            
        } label: {
            Text("My Action 1")
        }
        
        Divider()
        
        Menu {
            Button {
                
            } label: {
                Text("My Action 2")
            }
        } label: {
            Text("More")
        }
    }
```

<img src="https://github.com/user-attachments/assets/53ffdc21-080a-4948-84d4-e622f411c36b" width="900" alt="Context menu">

<div dir="rtl">

### تغبيش (blur) بقية الشاشة

</div>

```swift
ActiveText(message)
    .contextMenuPreview(backdrop: .blur(.regular))
    .contextMenuActions { element in [ .copy(element.value) ] }
```

<img src="https://github.com/user-attachments/assets/e3dcfc94-74d8-40b4-a31b-28f94e3483b6" width="900" alt="Preview with blur backdrop">

<div dir="rtl">

### أو تعتيمها (dim)

</div>

```swift
ActiveText(message)
    .contextMenuPreview(backdrop: .dim(opacity: 0.5))
    .contextMenuActions { element in [ .copy(element.value) ] }
```

<img src="https://github.com/user-attachments/assets/4b439ef0-63ed-42be-b9d9-f470bbcf3391" width="900" alt="Preview with dim backdrop">

<div dir="rtl">

---

## تمييز الضغط المستمر (Press-and-hold highlight)

عند الضغط على عنصر تُرسَم خلفه حبّة (pill) دائرية الحواف، مُلوّنة تلقائيًا بلون ذلك العنصر. مُفعّلة افتراضيًا.

</div>

```swift
ActiveText(post)
    .pressHighlight()                          // on (default)
    .pressHighlightColor(.yellow.opacity(0.3)) // …or a fixed tint
    .pressHighlightCornerRadius(8)             // …rounder pill
    .pressHighlight(for: [.hashtag, .mention]) // …only these types

ActiveText(post).pressHighlight(false)         // turn off
```

<div dir="rtl">

> يحتاج التمييز إلى hit-testing من UIKit. يتحوّل ActiveText إلى خلفية UIKit تلقائيًا عند إرفاق قائمة سياقية، أو اطلبها بِـ `.renderingEngine(.uiKit)`.

---

## بعض الحيل الإضافية

### التحقق مقابل قائمة مسموح بها (allow-list)

استخدم `ClosureParser` عندما لا يكفي الـ regex:

</div>

```swift
let valid: Set<String> = ["SAVE20", "WELCOME"]
let promo = ClosureParser(type: .custom(id: "promo", pattern: "")) { text in
    text.split(separator: " ").map(String.init)
        .filter(valid.contains)
        .compactMap { ActiveTextElement.make(matching: $0, in: text, type: .custom(id: "promo", pattern: "")) }
}

ActiveText("Use code SAVE20 today").parser(promo)
```

<div dir="rtl">

### قائمة أصلية بِـ SwiftUI مع عناصر عرض حقيقية

عندما تريد أزرار SwiftUI حقيقية (نطاقها كامل النص، لا لكل عنصر):

</div>

```swift
ActiveText(message)
    .menuItems {
        Button { copyAll() } label: { Label("Copy", systemImage: "doc.on.doc") }
        Divider()
        MyReportButton()
    } preview: {
        MyPreviewCard()
    }
```

<div dir="rtl">

### بديل جاهز بِـ UIKit خالص

</div>

```swift
let label = ActiveTextLabel()
label.update(text: "Hi @bob, see https://apple.com", types: [.mention, .url])
label.onTap(.mention) { print("mention:", $0) }
```

<div dir="rtl">

### نص طويل؟ حلّله خارج الـ main thread

</div>

```swift
ActiveText(veryLongArticle).asyncParsing()
```

<div dir="rtl">

---

## تحت الغطاء

<details>
<summary><strong>خلفيات العرض (Rendering backends)</strong> — متى تختار أيًا منها</summary>

| المحرّك      | العرض                    | نقاط القوة                                                  | القيود                               |
|--------------|--------------------------|------------------------------------------------------------|--------------------------------------|
| `.swiftUI`   | `Text(AttributedString)` | SwiftUI خالص؛ أفضل دعم لِـ Dynamic Type / RTL / الوصولية؛ قابل للتحريك. | لا قائمة ضغط مطوّل؛ حالة ضغط من النظام. |
| `.uiKit`     | `UILabel` + TextKit      | تمييز ضغط لكل عنصر؛ قوائم سياقية؛ hit-testing دقيق. | جسر `UIViewRepresentable`. |
| `.automatic` | يختار نيابةً عنك          | `.uiKit` عند ضبط قائمة سياقية، وإلا `.swiftUI`.      | —                                    |

تجعل خلفية SwiftUI العناصر قابلة للنقر عبر إرفاق رابط خاص `activetext://` بكل عنصر واعتراضه عبر `OpenURLAction`؛ دالة `.onURLTap` لديك تستقبل دائمًا الرابط الحقيقي، لا مخطط التوجيه.

</details>

<details>
<summary><strong>البنية المعمارية (Architecture)</strong> — طبقات باتجاه واحد</summary>

</div>

```
String
  │   Parsing      → [ActiveTextElement]   (RegexParser, DataDetectorParser,
  │                                          MarkdownParser, ClosureParser,
  │                                          orchestrated by ActiveTextScanner)
  ▼
[ActiveTextToken]  (Core: plain / element segmentation)
  │   Styling      → per-type ActiveTextStyle via ActiveTextTheme
  │   Rendering    → AttributedString / NSAttributedString
  ▼
SwiftUI `ActiveText`  /  UIKit `ActiveTextLabel`   (Adapters)
  │   Interaction  ← taps routed back through ActiveTextInteraction
```

<div dir="rtl">

تعتمد كل طبقة فقط على الطبقات التي فوقها — أضِف parser أو style أو backend دون المساس بالباقي. الشرح الكامل في [`Documentation/ARCHITECTURE.md`](Documentation/ARCHITECTURE.md).

</details>

<details>
<summary><strong>مساران للقوائم</strong> — UIKit مقابل SwiftUI</summary>

| المُعدِّل              | الخلفية  | المحتوى            | النطاق       | الرفع             |
|-----------------------|----------|--------------------|--------------|------------------|
| `.contextMenuActions` | UIKit    | DSL لِـ `.button`/`.divider`/`.submenu` → `UIMenu` | لكل عنصر  | الكلمة فقط        |
| `.menuItems`          | SwiftUI  | عناصر `Button`/`Divider` حقيقية / عروضك     | كامل النص   | كامل العرض / معاينة مخصّصة |

استخدم `.contextMenuActions` عندما تحتاج نطاقًا لكل رابط ورفعًا للكلمة فقط. واستخدم `.menuItems` عندما تريد عناصر عرض SwiftUI حقيقية. لا تجمع بينهما على نفس العرض.

إن `.contextMenuActions` هو DSL مبني على result-builder بدل `Button`/`Divider` الحرفية في SwiftUI، لأن تفاعل القائمة السياقية في UIKit يقبل فقط `UIMenuElement`، ولا يوجد جسر عام من `Button` في SwiftUI إلى `UIMenu`.

</details>

---

## المزايا

- **SwiftUI أولًا**، مع خلفية UIKit و `ActiveTextLabel` مستقل لتطبيقات UIKit الخالصة.
- يكتشف الروابط والـ mentions والـ hashtags والبريد وأرقام الهاتف + أي عدد من **أنماط regex / closure المخصّصة**.
- **نطاقات قابلة للنقر** مع دوال استدعاء لكل نوع أو شاملة.
- **تنسيق لكل نوع**: اللون، الخط، التسطير، تظليل الخلفية، حالة الضغط.
- مبني على `AttributedString` (SwiftUI) و TextKit (UIKit)؛ مع تأثيرات `TextRenderer` اختيارية على iOS 18+.
- **Dynamic Type و RTL والوصولية** متوفّرة مجانًا.
- روابط **Markdown** الاختيارية المضمّنة: `[label](url)`.
- **آمن مع async**: الاكتشاف خالص (pure) مع ذاكرة regex محمية بقفل؛ وواجهة فحص `async` للنصوص الطويلة.
- **أداء عالٍ**: اكتشاف بِـ O(n)، تخزين مؤقت للـ regex المُترجَم، عرض بِـ O(n).

## الاختبار

</div>

```bash
swift test
```

<div dir="rtl">

يغطي الـ parsers، وقواعد التداخل/الأولوية في الـ scanner، والتقطيع (tokenisation)، ونموذج العنصر/النوع، والتنسيق، والـ parsers المخصّصة، والـ Markdown، واختبارات أداء محدّدة زمنيًا.

## الأمثلة وتطبيق العرض

- `Examples/` — شاشات SwiftUI جاهزة، كل منها مع `#Preview` في Xcode.
- `DemoApp/` — هيكل تطبيق قابل للتشغيل (انظر `DemoApp/README.md`).

## الرخصة

MIT

</div>
