# دليل الإعداد — نظام النشر الآلي

النظام ٣ أجزاء: **عقل كلاودفلير** + **عامل قِثهب** + **بوت تلقرام**. كله مجاني.

---

## المكوّنات

```
الماسح (GitHub cron كل 10د)  →  يقرأ "تم تحديثها مؤخراً" بجلستك  →  يرسلها للعقل
العقل (Cloudflare)           →  طابور + منع تكرار + 10/ساعة + لوحة تحكم بالبوت
                             →  كل 3د يطلق تطبيقاً واحداً للعامل
عامل النشر (GitHub)          →  يحمّل + يحقن الدايلب + يرفع للقناة + يبلّغ العقل
```

---

## الأسرار المطلوبة (تُدخلها أنت — لا تمر بأي مكان غير مشفّر)

### في Cloudflare (أسرار الـ Worker)
| السر | القيمة |
|---|---|
| `TG_BOT_TOKEN` | توكن البوت |
| `OWNER_ID` | رقم حسابك بتلقرام (للوحة التحكم) |
| `GH_TOKEN` | توكن قِثهب (fine-grained، صلاحية repository_dispatch) |
| `GH_REPO` | `tazplus/taz-auto-publisher` |
| `ENQUEUE_SECRET` | كلمة سر تخترعها (نفسها بقِثهب) |

### في GitHub (Repository Secrets)
| السر | القيمة |
|---|---|
| `TG_USER_SESSION` / `TG_USER_API_ID` / `TG_USER_API_HASH` | جلسة القارئ (userbot) لقراءة @blatants |
| `SOURCE_CHANNEL` | قناة المصدر `@blatants` |
| `GEMINI_API_KEY` | مفتاح التعريب العربي (اختياري — يُسحب من المخ) |
| `DYLIB_B64` | `base64 -i fixipa.dylib` (ناتج الأمر) |
| `TG_API_ID` / `TG_API_HASH` | من my.telegram.org |
| `TG_BOT_TOKEN` | نفس توكن البوت |
| `TG_CHANNEL` | `@قناتك` أو `-100...` |
| `CHANNEL_FOOTER` | فوتر المنشور (اختياري) |
| `BRAIN_URL` | رابط الـ Worker (يظهر بعد النشر) |
| `ENQUEUE_SECRET` | نفس اللي بكلاودفلير |

---

## خطوات النشر (نسوّيها سوا وقت الربط)

1. **قاعدة البيانات:** `wrangler d1 create taz_publisher` → ننسخ الـ id في `wrangler.toml` → `wrangler d1 execute taz_publisher --file=schema.sql`
2. **نشر العقل:** `wrangler deploy` → يعطينا `BRAIN_URL`
3. **أسرار العقل:** `wrangler secret put <name>` لكل واحد فوق
4. **ويبهوك البوت:** نوجّه بوت تلقرام على `BRAIN_URL/telegram`
5. **أسرار قِثهب:** من صفحة المستودع → Settings → Secrets
6. **تشغيل:** الماسح يبدأ تلقائياً؛ ترسل `/start` للبوت وتشوف اللوحة

---

## ملاحظات أمان (مستودع عام)
- كل الأسرار في خزائن مشفّرة (Cloudflare/GitHub Secrets) — لا تظهر بالكود ولا السجلات.
- الملفات المؤقتة تُمسح بعد كل نشر (لا IPA محفوظ).
- لوحة التحكم للمالك فقط (تحقق `OWNER_ID`).
