# دليل نشر RemotePath على GitHub Pages

الدليل ده للنشر بعد مراجعة التغييرات محليًا. مفيش push أو نشر اتعمل ضمن Phase 04.

## 1. جهّز GitHub repository

1. سجّل دخولك على GitHub وأنشئ repository باسم `RemotePath` تحت حساب `ibrahim65k`.
2. لو هترفع تاريخ Git الموجود على جهازك، أنشئ المستودع فاضي من غير README أو License أو .gitignore علشان مايبقاش فيه تاريخ منفصل.
3. ثبّت Git for Windows لو الأمر `git --version` مش شغال. رابط التثبيت الرسمي: https://git-scm.com/install/win

## 2. راجع النسخة المحلية والاتصال

افتح PowerShell في `D:\projects\RemotePath` وشغّل الأوامر دي للمراجعة:

```powershell
git status --short --branch
git branch --show-current
git remote -v
git log -1 --oneline
```

افحص نتيجة `git remote -v` قبل أي تعديل. لو مفيش remote باسم origin، أضفه:

```powershell
git remote add origin https://github.com/ibrahim65k/RemotePath.git
```

لو origin موجود وبيشير لمكان مختلف، ما تستبدلوش إلا بعد ما تتأكد إن ده المستودع المقصود. عند التأكد استخدم `git remote set-url origin https://github.com/ibrahim65k/RemotePath.git`.

راجع التغييرات بـ `git status` و`git diff`، وبعدها أضف الملفات واعمل commit لو فيه تغييرات غير محفوظة:

```powershell
git add .
git status --short
git commit -m "Complete RemotePath Phase 04"
```

لو مفيش تغييرات للـcommit، تخطّى أمر commit. لو الفرع المحلي مش `main`، افحص الفروع والمستودع البعيد قبل إعادة تسميته أو الدمج. لا تستخدم force push. لو المستودع البعيد فيه commits، اسحبها وراجع الدمج قبل الدفع.

لرفع فرع main إلى مستودع فارغ فقط:

```powershell
git push -u origin main
```

GitHub قد يطلب تسجيل دخول عبر المتصفح أو مدير بيانات الاعتماد. ما تضعش كلمة السر أو token داخل الأمر.

## 3. فعّل GitHub Pages

1. افتح المستودع على GitHub.
2. ادخل **Settings → Pages**.
3. عند **Build and deployment** اختار **GitHub Actions** كمصدر.
4. افتح تبويب **Actions** وتابع workflow باسم **Deploy RemotePath to GitHub Pages**.
5. بعد نجاحه، افتح رابط الموقع اللي بيظهر في سجل النشر أو في Settings → Pages. إعدادات المشروع مبنية على عنوان المستودع https://ibrahim65k.github.io/RemotePath/ .

الـworkflow بيشتغل عند push إلى فرع main أو يدويًا من Actions. بيجهز مجلد `_site` لملفات الموقع فقط، وبعدها يرفعه وينشره. ملفات التوثيق وأرشيفات المراحل مش ضمن artifact المنشور.

## 4. فحص بعد النشر

افتح الصفحة الرئيسية، البحث، التصنيفات، تخصصًا، ودليلَي المنصات والأدوات. جرّب روابط مباشرة فيها query parameters وتأكد إن JSON وملفات CSS/JS بترجع بدون 404. راجع Search Console لاحقًا لو أضفت الموقع، وتأكد إن sitemap متاح على /RemotePath/sitemap.xml.

## مراجع رسمية

- GitHub Pages باستخدام workflow مخصص: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages
- اختيار مصدر النشر: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
- تثبيت Git for Windows: https://git-scm.com/install/win
