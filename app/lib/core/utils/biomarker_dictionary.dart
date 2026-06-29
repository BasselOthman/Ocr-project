class BiomarkerDictionary {
  static const Map<String, Map<String, String>> definitions = {
    'HGB': {
      'en':
          'Hemoglobin: A protein in red blood cells that carries oxygen. Low levels generally indicate anemia, while high levels can point to dehydration or other blood conditions.',
      'ar':
          'الهيموجلوبين: بروتين في خلايا الدم الحمراء ينقل الأكسجين. تشير المستويات المنخفضة عموماً إلى فقر الدم، بينما قد تشير المستويات المرتفعة إلى الجفاف أو حالات دم أخرى.',
    },
    'HCT': {
      'en':
          'Hematocrit: The proportion of your total blood volume that consists of red blood cells. It helps assess anemia or hydration status.',
      'ar':
          'الهيماتوكريت: نسبة حجم الدم الكلي المكون من خلايا الدم الحمراء. يساعد في تقييم فقر الدم أو حالة الجفاف.',
    },
    'RBC': {
      'en':
          'Red Blood Cells: The total number of red blood cells in your sample. Abnormal levels can indicate anemia, bleeding, or other red cell disorders.',
      'ar':
          'خلايا الدم الحمراء: العدد الإجمالي لخلايا الدم الحمراء في عينتك. يمكن أن تشير المستويات غير الطبيعية إلى فقر الدم أو النزيف أو اضطرابات خلايا الدم الحمراء الأخرى.',
    },
    'MCV': {
      'en':
          'MCV: Mean Corpuscular Volume. This measures the average size of your red blood cells. It helps determine the specific type of anemia (e.g., smaller cells indicate microcytic anemia).',
      'ar':
          'متوسط حجم الكريات (MCV): يقيس متوسط حجم خلايا الدم الحمراء. يساعد في تحديد نوع فقر الدم (مثل الخلايا الأصغر تشير إلى فقر الدم صغير الكريات).',
    },
    'MCH': {
      'en':
          'MCH: Mean Corpuscular Hemoglobin. This calculates the average amount of hemoglobin inside a single red blood cell.',
      'ar':
          'متوسط هيموجلوبين الكرية (MCH): يحسب متوسط كمية الهيموجلوبين داخل خلية دم حمراء واحدة.',
    },
    'MCHC': {
      'en':
          'MCHC: Mean Corpuscular Hemoglobin Concentration. This measures the concentration of hemoglobin within a specific volume of red blood cells.',
      'ar':
          'تركيز هيموجلوبين الكرية المتوسط (MCHC): يقيس تركيز الهيموجلوبين داخل حجم معين من خلايا الدم الحمراء.',
    },
    'RDW': {
      'en':
          'RDW: Red Cell Distribution Width. This measures the variation in the size of your red blood cells. A high variation is often seen in certain nutritional deficiency anemias.',
      'ar':
          'عرض توزيع خلايا الدم الحمراء (RDW): يقيس التباين في حجم خلايا الدم الحمراء. غالباً ما يُلاحظ التباين المرتفع في بعض أنواع فقر الدم الناجم عن نقص التغذية.',
    },
    'PLT': {
      'en':
          'Platelet Count: Measures the cells that help your blood clot. Low levels increase the risk of bleeding, while high levels can lead to abnormal clotting.',
      'ar':
          'عدد الصفائح الدموية: يقيس الخلايا التي تساعد على تجلط الدم. تزيد المستويات المنخفضة من خطر النزيف، بينما قد تؤدي المستويات المرتفعة إلى تجلط غير طبيعي.',
    },
    'WBC': {
      'en':
          'White Blood Cells: The total number of white blood cells. This is a key indicator of your immune system\'s status; high levels suggest infection or inflammation, while low levels suggest compromised immunity.',
      'ar':
          'خلايا الدم البيضاء: العدد الإجمالي لخلايا الدم البيضاء. هذا مؤشر رئيسي لحالة جهازك المناعي؛ تشير المستويات المرتفعة إلى العدوى أو الالتهاب، بينما تشير المستويات المنخفضة إلى ضعف المناعة.',
    },
    'NEUT': {
      'en':
          'Neutrophils: The most common type of white blood cell, primarily acting as the first responders to bacterial infections.',
      'ar':
          'الخلايا المتعادلة (النيوتروفيل): النوع الأكثر شيوعاً من خلايا الدم البيضاء، وتعمل بشكل أساسي كخط دفاع أول ضد الالتهابات البكتيرية.',
    },
    'LYMPH': {
      'en':
          'Lymphocytes: White blood cells vital for producing antibodies and fighting off viral infections.',
      'ar':
          'الخلايا اللمفاوية: خلايا دم بيضاء حيوية لإنتاج الأجسام المضادة ومحاربة الالتهابات الفيروسية.',
    },
    'MONO': {
      'en':
          'Monocytes: White blood cells responsible for removing dead cells and fighting chronic infections.',
      'ar':
          'الخلايا الوحيدة (المونوسيت): خلايا دم بيضاء مسؤولة عن إزالة الخلايا الميتة ومكافحة الالتهابات المزمنة.',
    },
    'EOS': {
      'en':
          'Eosinophils: White blood cells heavily involved in allergic reactions and combating parasitic infections.',
      'ar':
          'الخلايا الحمضية (الإيوسينوفيل): خلايا دم بيضاء تشارك بشكل كبير في تفاعلات الحساسية ومكافحة الالتهابات الطفيلية.',
    },
    'BASO': {
      'en':
          'Basophils: White blood cells involved in inflammatory responses, particularly allergic reactions.',
      'ar':
          'الخلايا القلوية (البازوفيل): خلايا دم بيضاء تشارك في الاستجابات الالتهابية، وخاصة تفاعلات الحساسية.',
    },
    'GLU': {
      'en':
          'Random Blood Glucose: Measures blood sugar levels at a random moment in time, regardless of when you last ate. It is used for diabetes screening.',
      'ar':
          'جلوكوز الدم العشوائي: يقيس مستويات السكر في الدم في لحظة عشوائية، بغض النظر عن وقت آخر وجبة. يُسخدم لفحص مرض السكري.',
    },
    'HBA1C': {
      'en':
          'Haemoglobin A1C: Measures your average blood sugar level over the past 2 to 3 months. It is the gold standard for diagnosing and monitoring diabetes.',
      'ar':
          'الهيموجلوبين السكري (A1C): يقيس متوسط مستوى السكر في الدم خلال الشهرين إلى الثلاثة أشهر الماضية. وهو المعيار الذهبي لتشخيص مرض السكري ومراقبته.',
    },
    'ALT': {
      'en':
          'SGPT (ALT): Alanine Aminotransferase. A liver enzyme. High levels indicate liver damage or inflammation.',
      'ar':
          'إنزيم الكبد (ALT): ناقلة أمين الألانين. إنزيم كبدي. المستويات المرتفعة تشير إلى تلف أو التهاب في الكبد.',
    },
    'AST': {
      'en':
          'SGOT (AST): Aspartate Aminotransferase. An enzyme found in the liver, heart, and muscles. Elevated levels can indicate liver damage, muscle injury, or other tissue damage.',
      'ar':
          'إنزيم الكبد (AST): ناقلة أمين الأسبارتات. إنزيم يوجد في الكبد والقلب والعضلات. تشير المستويات المرتفعة إلى تلف الكبد أو إصابة العضلات.',
    },
    'CREAT': {
      'en':
          'Serum Creatinine: A chemical waste product generated by muscle metabolism that is filtered out by the kidneys. High levels typically indicate impaired kidney function.',
      'ar':
          'الكرياتينين في المصل: فضلات كيميائية ينتجها التمثيل الغذائي للعضلات وتصفيها الكلى. تشير المستويات المرتفعة عادةً إلى ضعف وظائف الكلى.',
    },
    'TSH': {
      'en':
          'TSH: Thyroid Stimulating Hormone. A hormone produced by the pituitary gland that tells the thyroid gland to make and release thyroid hormones. Abnormal levels indicate an underactive or overactive thyroid.',
      'ar':
          'الهرمون المنبه للغدة الدرقية (TSH): هرمون تنتجه الغدة النخامية يوجه الغدة الدرقية لإنتاج وإطلاق هرمونات الدرقية. تشير المستويات غير الطبيعية إلى قصور أو فرط نشاط الغدة الدرقية.',
    },
    'T4': {
      'en':
          'Free T4: The active, unbound form of thyroxine, the main hormone produced by the thyroid gland. It is used alongside TSH to evaluate how well the thyroid is functioning.',
      'ar':
          'هرمون T4 الحر: الشكل النشط غير المرتبط من هرمون الثايروكسين، الهرمون الرئيسي الذي تنتجه الغدة الدرقية. يُستخدم مع TSH لتقييم كفاءة عمل الغدة الدرقية.',
    },
    'HBSAG': {
      'en':
          'HBs Ag: Hepatitis B Surface Antigen. A protein on the surface of the Hepatitis B virus. A positive result indicates a current Hepatitis B infection.',
      'ar':
          'المستضد السطحي لالتهاب الكبد ب (HBs Ag): بروتين على سطح فيروس التهاب الكبد ب. تشير النتيجة الإيجابية إلى إصابة حالية بالفيروس.',
    },
    'HCVAB': {
      'en':
          'HCV Ab: Hepatitis C Antibody. Detects antibodies the body produces in response to the Hepatitis C virus. A positive result indicates a past or present infection.',
      'ar':
          'الأجسام المضادة لالتهاب الكبد ج (HCV Ab): يكشف عن الأجسام المضادة التي ينتجها الجسم استجابةً لفيروس التهاب الكبد ج. تشير النتيجة الإيجابية إلى إصابة سابقة أو حالية.',
    },
    // Remaining ones
    'ALB': {
      'en':
          'Albumin: A major protein produced by the liver. Helps keep fluid from leaking out of blood vessels and nourishes tissues.',
      'ar':
          'الألبومين: بروتين رئيسي ينتجه الكبد. يساعد في منع تسرب السوائل من الأوعية الدموية ويغذي الأنسجة.',
    },
    'ALP': {
      'en':
          'Alkaline Phosphatase: An enzyme related to the bile ducts, kidneys, and bones. High levels can indicate liver disease or bone disorders.',
      'ar':
          'الفوسفاتاز القلوي: إنزيم مرتبط بالقنوات الصفراوية والكبد والعظام. المستويات المرتفعة قد تشير إلى مشاكل في الكبد أو العظام.',
    },
    'DBIL': {
      'en':
          'Direct Bilirubin: A form of bilirubin processed by the liver. High levels help identify gallbladder or bile duct blockages.',
      'ar':
          'البيليروبين المباشر: شكل من أشكال البيليروبين يعالجه الكبد. يساعد ارتفاعه في كشف انسداد القنوات الصفراوية.',
    },
    'BIL': {
      'en':
          'Total Bilirubin: A byproduct of the breakdown of red blood cells. Elevated levels cause jaundice and suggest liver or blood disorders.',
      'ar':
          'البيليروبين الكلي: ناتج عن تكسير خلايا الدم الحمراء. المستويات المرتفعة تسبب اليرقان وتشير لمشاكل الكبد أو الدم.',
    },
    'FERRITIN': {
      'en':
          'Ferritin: A blood protein containing iron. Helps measure how much iron your body has stored.',
      'ar':
          'الفيريتين: بروتين دم يحتوي على الحديد. يساعد في قياس كمية الحديد المخزنة في الجسم.',
    },
    'TP': {
      'en':
          'Total Protein: Measures the total amount of albumin and globulin in your blood, indicating nutritional and organ health.',
      'ar':
          'البروتين الكلي: يقيس الكمية الإجمالية للألبومين والجلوبولين في الدم، مما يشير إلى الصحة الغذائية وصحة الأعضاء.',
    },
    'T3': {
      'en':
          'Triiodothyronine: An active thyroid hormone. Helps regulate energy production and metabolic pathways.',
      'ar':
          'ثلاثي يود الثيرونين (T3): هرمون نشط للغدة الدرقية. يساعد في تنظيم إنتاج الطاقة والتمثيل الغذائي.',
    },
    'UREA': {
      'en':
          'Urea Nitrogen: A waste product cleared by the kidneys. Elevated levels point to kidney dysfunction or dehydration.',
      'ar':
          'اليوريا: فضلات تتخلص منها الكلى. تشير المستويات المرتفعة إلى خلل في الكلى أو الجفاف.',
    },
  };

  static String getDefinition(String biomarker, String languageCode) {
    // Normalize string (e.g., handling variations like Glu or glucose)
    String key = biomarker.toUpperCase();

    // Normalize mappings to dictionary keys
    if (key.contains('HAEMOGLOBIN') ||
        key.contains('HEMOGLOBIN') ||
        key == 'HGB') {
      key = 'HGB';
    } else if (key.contains('HAEMATOCRIT') ||
        key.contains('HEMATOCRIT') ||
        key.contains('PCV') ||
        key == 'HCT') {
      key = 'HCT';
    } else if (key.contains('RBC') || key.contains('RED BLOOD CELL')) {
      key = 'RBC';
    } else if (key.contains('MCV')) {
      key = 'MCV';
    } else if (key.contains('MCH')) {
      key = 'MCH';
    } else if (key.contains('MCHC')) {
      key = 'MCHC';
    } else if (key.contains('RDW')) {
      key = 'RDW';
    } else if (key.contains('PLATELET') || key == 'PLT') {
      key = 'PLT';
    } else if (key.contains('WBC') ||
        key.contains('WHITE BLOOD CELL') ||
        key.contains('LEUCOCYT') ||
        key.contains('LEUKOCYT')) {
      key = 'WBC';
    } else if (key.contains('NEUTROPHIL') || key == 'NEUT') {
      key = 'NEUT';
    } else if (key.contains('LYMPHOCYTE') || key == 'LYMPH') {
      key = 'LYMPH';
    } else if (key.contains('MONOCYTE') || key == 'MONO') {
      key = 'MONO';
    } else if (key.contains('EOSINOPHIL') || key == 'EOS') {
      key = 'EOS';
    } else if (key.contains('BASOPHIL') || key == 'BASO') {
      key = 'BASO';
    } else if (key.contains('GLUCOSE') ||
        key.contains('GLU') ||
        key.contains('RBG')) {
      key = 'GLU';
    } else if (key.contains('HBA1C') || key.contains('A1C')) {
      key = 'HBA1C';
    } else if (key.contains('ALT') || key.contains('SGPT')) {
      key = 'ALT';
    } else if (key.contains('AST') || key.contains('SGOT')) {
      key = 'AST';
    } else if (key.contains('CREATININE') || key == 'CREAT') {
      key = 'CREAT';
    } else if (key.contains('TSH')) {
      key = 'TSH';
    } else if (key.contains('T4') || key.contains('THYROXINE')) {
      key = 'T4';
    } else if (key.contains('HBS') || key.contains('HEPATITIS B')) {
      key = 'HBSAG';
    } else if (key.contains('HCV') || key.contains('HEPATITIS C')) {
      key = 'HCVAB';
    }

    // Find matches
    if (definitions.containsKey(key)) {
      return definitions[key]![languageCode] ?? definitions[key]!['en']!;
    }

    for (String k in definitions.keys) {
      if (key.contains(k) || k.contains(key)) {
        return definitions[k]![languageCode] ?? definitions[k]!['en']!;
      }
    }

    // Default dynamic fallback if not found in dictionary
    return languageCode == 'ar'
        ? '$biomarker: مؤشر حيوي مخبري. يقيس هذا الفحص تركيز $biomarker في الدم لتقييم الوظائف الفسيولوجية العامة والصحة الأيضية.'
        : '$biomarker: A laboratory biomarker. This test measures the concentration of $biomarker in your blood to evaluate general physiological function and metabolic health.';
  }
}
