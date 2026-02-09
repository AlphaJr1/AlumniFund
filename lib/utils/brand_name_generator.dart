import 'dart:math';

class BrandNameGenerator {
  static final Random _random = Random();

  // 100+ brand names yang keren dan beragam
  static const List<String> _brandNames = [
    // Mythological & Legendary
    'PHOENIX',
    'ATLAS',
    'TITAN',
    'NEXUS',
    'ZENITH',
    'AURORA',
    'OLYMPUS',
    'VALHALLA',
    'ELYSIUM',
    'ARCADIA',
    'AVALON',
    'ASGARD',
    'PANTHEON',
    'ODYSSEY',
    'AEGIS',
    
    // Nature & Elements
    'HORIZON',
    'SUMMIT',
    'CASCADE',
    'ECLIPSE',
    'SOLSTICE',
    'EQUINOX',
    'MERIDIAN',
    'COSMOS',
    'NEBULA',
    'STELLAR',
    'LUNAR',
    'SOLAR',
    'TERRA',
    'AQUA',
    'IGNITE',
    
    // Abstract Concepts
    'UNITY',
    'SYNERGY',
    'MOMENTUM',
    'CATALYST',
    'PARADIGM',
    'LEGACY',
    'GENESIS',
    'INFINITY',
    'ETERNITY',
    'HARMONY',
    'SYMPHONY',
    'RESONANCE',
    'ESSENCE',
    'PINNACLE',
    'APEX',
    
    // Modern & Tech
    'VERTEX',
    'MATRIX',
    'QUANTUM',
    'CIPHER',
    'VECTOR',
    'PIXEL',
    'BINARY',
    'NEURAL',
    'DIGITAL',
    'CYBER',
    'NEXGEN',
    'TECHNO',
    'FUSION',
    'SYNTH',
    'CHROME',
    
    // Power & Strength
    'VALOR',
    'TRIUMPH',
    'VICTORY',
    'CHAMPION',
    'FORTRESS',
    'BASTION',
    'CITADEL',
    'EMPIRE',
    'DYNASTY',
    'SOVEREIGN',
    'IMPERIAL',
    'ROYAL',
    'NOBLE',
    'ELITE',
    'PRIME',
    
    // Vision & Future
    'VISION',
    'ASPIRE',
    'ELEVATE',
    'ASCEND',
    'EVOLVE',
    'EMERGE',
    'PIONEER',
    'VENTURE',
    'FRONTIER',
    'ODYSSEY',
    'VOYAGE',
    'QUEST',
    'PURSUIT',
    'AMBITION',
    'DREAM',
    
    // Unique & Creative
    'LUMINA',
    'SPECTRA',
    'PRISMA',
    'AETHER',
    'ZEPHYR',
    'NOVA',
    'VORTEX',
    'HELIX',
    'SPIRAL',
    'RADIANT',
    'VIVID',
    'VIBRANT',
    'KINETIC',
    'DYNAMIC',
    'PULSE',
    
    // Community & Together
    'ALLIANCE',
    'COALITION',
    'COLLECTIVE',
    'GUILD',
    'CIRCLE',
    'SPHERE',
    'ORBIT',
    'CLUSTER',
    'NETWORK',
    'NEXUS',
    'BOND',
    'LINK',
    'CONNECT',
    'UNITE',
    'TOGETHER',
    
    // Excellence & Quality
    'PRESTIGE',
    'EXCELLENCE',
    'SUPREME',
    'ULTIMATE',
    'OPTIMAL',
    'PERFECT',
    'FLAWLESS',
    'PRISTINE',
    'REFINED',
    'POLISHED',
    'BRILLIANT',
    'STELLAR',
    'SUPERIOR',
    'PREMIUM',
    'DELUXE',
    
    // Innovation & Progress
    'INNOVATE',
    'ADVANCE',
    'PROGRESS',
    'FORWARD',
    'ONWARD',
    'UPWARD',
    'BREAKTHROUGH',
    'REVOLUTION',
    'TRANSFORM',
    'REFORM',
    'RENEW',
    'REVIVE',
    'RESTORE',
    'REBUILD',
    'REIMAGINE',
  ];

  /// Get a random brand name
  static String getRandomName() {
    return _brandNames[_random.nextInt(_brandNames.length)];
  }

  /// Get a list of random brand names (no duplicates in the list)
  static List<String> getRandomNames(int count) {
    final shuffled = List<String>.from(_brandNames)..shuffle(_random);
    return shuffled.take(count.clamp(1, _brandNames.length)).toList();
  }

  /// Get total count of available names
  static int get totalNames => _brandNames.length;
}
