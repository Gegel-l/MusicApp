import '../models/instrument_configurator.dart';
import '../models/product.dart';

/// Пресеты опций конфигуратора по категории и по ключевым словам в названии/описании.
class InstrumentConfiguratorPresets {
  InstrumentConfiguratorPresets._();

  static String _ctx(Product p) =>
      '${p.name} ${p.description} ${p.specs.values.join(' ')}'.toLowerCase();

  static List<ProductColorOption> colorsFor(Product p) {
    if (p.configuratorColors.isNotEmpty) return p.configuratorColors;
    if (!Product.kInstrumentCategoriesWithDefaultConfigurator.contains(p.category)) {
      return const [];
    }
    final s = _ctx(p);
    switch (p.category) {
      case 'Струнные':
        if (s.contains('контрабас')) {
          return const [
            ProductColorOption(id: 'cb_sp', label: 'Отделка: спрус / тёмный', hex: '#4E342E'),
            ProductColorOption(id: 'cb_nat', label: 'Натуральный лак', hex: '#A1887F'),
            ProductColorOption(id: 'cb_blk', label: 'Чёрный полиэстер', hex: '#212121'),
          ];
        }
        if (s.contains('виолончел')) {
          return const [
            ProductColorOption(id: 'vc_nat', label: 'Нитро-лак классический', hex: '#D7A574'),
            ProductColorOption(id: 'vc_brn', label: 'Тёмный глянец', hex: '#4E342E'),
          ];
        }
        if (s.contains('скрип')) {
          return const [
            ProductColorOption(id: 'sv_nat', label: 'Корпус: натуральный лак', hex: '#D7A574'),
            ProductColorOption(id: 'sv_ant', label: 'Корпус: антик', hex: '#5D4037'),
            ProductColorOption(id: 'sv_ebny', label: 'Гриф: эбеновое дерево', hex: '#212121'),
          ];
        }
        if (s.contains('укуле')) {
          return const [
            ProductColorOption(id: 'uk_mah', label: 'Махагони', hex: '#8D6E63'),
            ProductColorOption(id: 'uk_koa', label: 'Коа / тропическое', hex: '#BCAAA4'),
            ProductColorOption(id: 'uk_brt', label: 'Яркий декор', hex: '#FF7043'),
          ];
        }
        if (s.contains('арф')) {
          return const [
            ProductColorOption(id: 'hp_gld', label: 'Позолота механики', hex: '#FFD54F'),
            ProductColorOption(id: 'hp_nat', label: 'Натуральное дерево', hex: '#D7CCC8'),
            ProductColorOption(id: 'hp_wht', label: 'Белая отделка', hex: '#FAFAFA'),
          ];
        }
        if (s.contains('бас') && s.contains('гитар')) {
          return const [
            ProductColorOption(id: 'bg_sb', label: 'Санберст', hex: '#6D4C41'),
            ProductColorOption(id: 'bg_blk', label: 'Чёрный', hex: '#263238'),
            ProductColorOption(id: 'bg_mtl', label: 'Металлик', hex: '#78909C'),
          ];
        }
        if (s.contains('гитар') || s.contains('банджо') || s.contains('мандолин')) {
          return const [
            ProductColorOption(id: 'gt_nat', label: 'Натуральное дерево', hex: '#A1887F'),
            ProductColorOption(id: 'gt_sb', label: 'Санберст', hex: '#5D4037'),
            ProductColorOption(id: 'gt_blk', label: 'Чёрный матовый', hex: '#212121'),
            ProductColorOption(id: 'gt_wht', label: 'Белый', hex: '#ECEFF1'),
          ];
        }
        return const [
          ProductColorOption(id: 'st_gen', label: 'Классическая отделка', hex: '#A1887F'),
          ProductColorOption(id: 'st_dark', label: 'Тёмный лак', hex: '#3E2723'),
          ProductColorOption(id: 'st_red', label: 'Винно-красный', hex: '#7D1F1F'),
        ];

      case 'Клавишные':
        if (s.contains('аккордеон') || s.contains('баян')) {
          return const [
            ProductColorOption(id: 'ac_red', label: 'Корпус бордовый', hex: '#8B1538'),
            ProductColorOption(id: 'ac_blk', label: 'Чёрный лак', hex: '#212121'),
            ProductColorOption(id: 'ac_pearl', label: 'Перламутр / инкрустация', hex: '#E0E0E0'),
          ];
        }
        if (s.contains('синтез') || s.contains('workstation') || s.contains('миди')) {
          return const [
            ProductColorOption(id: 'syn_blk', label: 'Панель чёрная', hex: '#212121'),
            ProductColorOption(id: 'syn_wht', label: 'Панель белая', hex: '#F5F5F5'),
            ProductColorOption(id: 'syn_wood', label: 'Деревянные бока', hex: '#6D4C41'),
          ];
        }
        if (s.contains('орган')) {
          return const [
            ProductColorOption(id: 'or_wal', label: 'Корпус орех', hex: '#5D4037'),
            ProductColorOption(id: 'or_blk', label: 'Чёрный пластик / лак', hex: '#212121'),
            ProductColorOption(id: 'or_map', label: 'Клён светлый', hex: '#FFCC80'),
          ];
        }
        return const [
          ProductColorOption(id: 'kb_blk', label: 'Корпус чёрный матовый', hex: '#212121'),
          ProductColorOption(id: 'kb_wht', label: 'Корпус белый глянцевый', hex: '#ECEFF1'),
          ProductColorOption(id: 'kb_rosewood', label: 'Тёмное дерево (розовое)', hex: '#4E342E'),
          ProductColorOption(id: 'kb_maple', label: 'Светлый клён', hex: '#D7CCC8'),
        ];

      case 'Духовые':
        if (s.contains('сакс') || s.contains('саксофон')) {
          return const [
            ProductColorOption(id: 'sx_gl', label: 'Позолоченное лаковое покрытие', hex: '#FFB300'),
            ProductColorOption(id: 'sx_sl', label: 'Серебристый лак', hex: '#B0BEC5'),
            ProductColorOption(id: 'sx_brnz', label: 'Антик / бронза', hex: '#8D6E63'),
          ];
        }
        if (s.contains('флейт') || s.contains('окарин')) {
          return const [
            ProductColorOption(id: 'fl_sl', label: 'Серебро / никель', hex: '#CFD8DC'),
            ProductColorOption(id: 'fl_wd', label: 'Дерево / бамбук', hex: '#8D6E63'),
          ];
        }
        if (s.contains('тромбон') || s.contains('труба') || s.contains('валторн')) {
          return const [
            ProductColorOption(id: 'br_la', label: 'Лак золото / медь', hex: '#FFA000'),
            ProductColorOption(id: 'br_sl', label: 'Серебро', hex: '#ECEFF1'),
          ];
        }
        if (s.contains('кларнет') || s.contains('гобой') || s.contains('фагот')) {
          return const [
            ProductColorOption(id: 'wd_gr', label: 'Гренадилла / тёмное дерево', hex: '#212121'),
            ProductColorOption(id: 'wd_cl', label: 'Клареновое дерево', hex: '#5D4037'),
          ];
        }
        return const [
          ProductColorOption(id: 'wnd_sl', label: 'Покрытие серебро / лак', hex: '#CFD8DC'),
          ProductColorOption(id: 'wnd_gd', label: 'Позолота', hex: '#FFC107'),
          ProductColorOption(id: 'wnd_br', label: 'Латунь патина', hex: '#BF953F'),
        ];

      case 'Ударные':
        if (s.contains('тарелк')) {
          return const [
            ProductColorOption(id: 'cy_bn', label: 'Бронзовый сплав K', hex: '#B8860B'),
            ProductColorOption(id: 'cy_br', label: 'Латунная серия', hex: '#FFB74D'),
            ProductColorOption(id: 'cy_dk', label: 'Тёмная патина', hex: '#4E342E'),
          ];
        }
        if (s.contains('кахон') || s.contains('джембе') || s.contains('бонго')) {
          return const [
            ProductColorOption(id: 'perc_nat', label: 'Натуральное дерево', hex: '#A1887F'),
            ProductColorOption(id: 'perc_bur', label: 'Обожжённое / патина', hex: '#3E2723'),
          ];
        }
        return const [
          ProductColorOption(id: 'dr_red', label: 'Обода красный блеск', hex: '#C62828'),
          ProductColorOption(id: 'dr_blk', label: 'Обода чёрные', hex: '#212121'),
          ProductColorOption(id: 'dr_wd', label: 'Корпус дерево', hex: '#6D4C41'),
          ProductColorOption(id: 'dr_chr', label: 'Хром / металл', hex: '#90A4AE'),
        ];

      case 'Электронные':
        if (s.contains('гитар') && (s.contains('усил') || s.contains('комбо'))) {
          return const [
            ProductColorOption(id: 'amp_twd', label: 'Твид / винтаж', hex: '#D7CCC8'),
            ProductColorOption(id: 'amp_blk', label: 'Чёрный гриль', hex: '#212121'),
            ProductColorOption(id: 'amp_blu', label: 'Синий / кастом', hex: '#1565C0'),
          ];
        }
        if (s.contains('педаль') || s.contains('стомпбокс')) {
          return const [
            ProductColorOption(id: 'fx_mtl', label: 'Корпус металл', hex: '#546E7A'),
            ProductColorOption(id: 'fx_neo', label: 'Неон / графика', hex: '#7C4DFF'),
          ];
        }
        if (s.contains('науш') || s.contains('монитор')) {
          return const [
            ProductColorOption(id: 'hp_blk', label: 'Чёрный матовый', hex: '#212121'),
            ProductColorOption(id: 'hp_slv', label: 'Серебристый', hex: '#B0BEC5'),
            ProductColorOption(id: 'hp_wht', label: 'Белый', hex: '#FAFAFA'),
          ];
        }
        return const [
          ProductColorOption(id: 'el_blk', label: 'Корпус чёрный', hex: '#212121'),
          ProductColorOption(id: 'el_slv', label: 'Алюминий / серебро', hex: '#90A4AE'),
          ProductColorOption(id: 'el_wood', label: 'Деревянные вставки', hex: '#6D4C41'),
        ];
      default:
        return const [];
    }
  }

  static List<ProductAccessoryOption> accessoriesFor(Product p) {
    if (p.configuratorAccessories.isNotEmpty) return p.configuratorAccessories;
    if (!Product.kInstrumentCategoriesWithDefaultConfigurator.contains(p.category)) {
      return const [];
    }
    final s = _ctx(p);
    switch (p.category) {
      case 'Струнные':
        if (s.contains('виолончел') ||
            (s.contains('скрип') && !s.contains('гитар'))) {
          return const [
            ProductAccessoryOption(id: 'sv_bow_case', label: 'Футляр для смычка', priceAddon: 1200),
            ProductAccessoryOption(id: 'sv_rosin_set', label: 'Канифоль премиум + тряпка', priceAddon: 550),
            ProductAccessoryOption(id: 'sv_shoulder', label: 'Подплечник / упор', priceAddon: 1800),
          ];
        }
        if (s.contains('контрабас')) {
          return const [
            ProductAccessoryOption(id: 'cb_bow', label: 'Смычок в футляре', priceAddon: 4900),
            ProductAccessoryOption(id: 'cb_rock_stand', label: 'Стойка / подбородник оркестровый', priceAddon: 2600),
          ];
        }
        if (s.contains('укуле')) {
          return const [
            ProductAccessoryOption(id: 'uk_strings', label: 'Запасной комплект струн', priceAddon: 450),
            ProductAccessoryOption(id: 'uk_bag_soft', label: 'Мягкий чехол', priceAddon: 990),
          ];
        }
        if (s.contains('гитар') || s.contains('бас')) {
          return const [
            ProductAccessoryOption(id: 'gt_pick', label: 'Набор медиаторов + держатель', priceAddon: 350),
            ProductAccessoryOption(id: 'gt_strings', label: 'Запасной комплект струн', priceAddon: 1200),
            ProductAccessoryOption(id: 'gt_strap', label: 'Ремень усиленный', priceAddon: 890),
            ProductAccessoryOption(id: 'gt_tuner_clip', label: 'Клиповый тюнер', priceAddon: 1490),
          ];
        }
        return const [
          ProductAccessoryOption(id: 'st_strings', label: 'Комплект струн', priceAddon: 990),
          ProductAccessoryOption(id: 'st_case', label: 'Чехол / лёгкий кейс', priceAddon: 2490),
        ];

      case 'Клавишные':
        if (s.contains('аккордеон') || s.contains('баян')) {
          return const [
            ProductAccessoryOption(id: 'ac_straps', label: 'Ремни + фурнитура', priceAddon: 1100),
            ProductAccessoryOption(id: 'ac_case', label: 'Футляр жёсткий', priceAddon: 5500),
          ];
        }
        return const [
          ProductAccessoryOption(id: 'kb_bench', label: 'Банкетка / стул', priceAddon: 4500),
          ProductAccessoryOption(id: 'kb_cover', label: 'Чехол-пыльник', priceAddon: 1900),
          ProductAccessoryOption(id: 'kb_pedal', label: 'Педаль сустейна (если поддерживается)', priceAddon: 3200),
          ProductAccessoryOption(id: 'kb_headph', label: 'Наушники для тихих репетиций', priceAddon: 2200),
        ];

      case 'Духовые':
        return const [
          ProductAccessoryOption(id: 'wnd_reed', label: 'Трости / платки комплект', priceAddon: 650),
          ProductAccessoryOption(id: 'wnd_stand', label: 'Подставка оркестровая', priceAddon: 1200),
          ProductAccessoryOption(id: 'wnd_swab', label: 'Ерши / уход / смазка', priceAddon: 480),
          ProductAccessoryOption(id: 'wnd_mute', label: 'Сурдина / кейс аксессуаров', priceAddon: 890),
        ];

      case 'Ударные':
        if (s.contains('тарелк')) {
          return const [
            ProductAccessoryOption(id: 'cy_pack', label: 'Фетры + стойки для тарелок', priceAddon: 2100),
            ProductAccessoryOption(id: 'cy_bag', label: 'Сумка для тарелок', priceAddon: 3200),
          ];
        }
        return const [
          ProductAccessoryOption(id: 'dr_sticks', label: 'Палочки несколько пар', priceAddon: 790),
          ProductAccessoryOption(id: 'dr_pedal', label: 'Транспорт / педаль мультирама', priceAddon: 2890),
          ProductAccessoryOption(id: 'dr_cymbal_stand', label: 'Стойка для тарелок', priceAddon: 3500),
          ProductAccessoryOption(id: 'dr_rug', label: 'Коврик под установку', priceAddon: 1500),
        ];

      case 'Электронные':
        return const [
          ProductAccessoryOption(id: 'el_cable', label: 'Инструментальный кабель 3 м', priceAddon: 990),
          ProductAccessoryOption(id: 'el_psu', label: 'Блок питания / адаптер запасной', priceAddon: 1800),
          ProductAccessoryOption(id: 'el_rack', label: 'Рэк-ушки / крепёж', priceAddon: 1400),
          ProductAccessoryOption(id: 'el_bag', label: 'Сумка для гитарного процессора', priceAddon: 2200),
        ];
      default:
        return const [];
    }
  }
}
