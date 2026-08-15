import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

// ─── Org Hierarchy Screen ─────────────────────────────────────────────────────
class OrgHierarchyScreen extends StatefulWidget {
  const OrgHierarchyScreen({super.key});

  @override
  State<OrgHierarchyScreen> createState() => _OrgHierarchyScreenState();
}

class _OrgHierarchyScreenState extends State<OrgHierarchyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCountry = 'All';

  final List<String> _countries = [
    'All',
    'Global',
    'Iraq',
    'Saudi Arabia',
    'UAE',
    'Jordan',
    'Kuwait',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Demo Org Data ──────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _orgData = [
    // ── Level 0: Founder ──
    {
      'id': 'founder',
      'name': 'Ahmad Al-Madar',
      'role': 'Founder & Owner',
      'level': 0,
      'country': 'Global',
      'dept': 'Executive',
      'avatar':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=80&h=80&fit=crop',
      'email': 'founder@madar.com',
      'phone': '+964 770 000 0001',
      'status': 'active',
      'color': 0xFFFFD700,
      'parentId': null,
    },
    // ── Level 1: Global CEO ──
    {
      'id': 'global_ceo',
      'name': 'Khalid Al-Rashidi',
      'role': 'Global / Group CEO',
      'level': 1,
      'country': 'Global',
      'dept': 'Executive',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_11b522a02-1763295866659.png',
      'email': 'ceo@madar.com',
      'phone': '+964 770 000 0002',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'founder',
    },
    // ── Level 2: Global C-Suite ──
    {
      'id': 'global_coo',
      'name': 'Sara Al-Hussain',
      'role': 'Global COO',
      'level': 2,
      'country': 'Global',
      'dept': 'Operations',
      'avatar':
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=80&h=80&fit=crop',
      'email': 'coo@madar.com',
      'phone': '+964 770 000 0003',
      'status': 'active',
      'color': 0xFF0D47A1,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cfo',
      'name': 'Omar Al-Tamimi',
      'role': 'Global CFO',
      'level': 2,
      'country': 'Global',
      'dept': 'Finance',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_160c4a9be-1767883243817.png',
      'email': 'cfo@madar.com',
      'phone': '+964 770 000 0004',
      'status': 'active',
      'color': 0xFF1B5E20,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cto',
      'name': 'Lina Karimi',
      'role': 'Global CTO',
      'level': 2,
      'country': 'Global',
      'dept': 'Technology',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1988db2b9-1763291835437.png',
      'email': 'cto@madar.com',
      'phone': '+964 770 000 0005',
      'status': 'active',
      'color': 0xFF4A148C,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cmo',
      'name': 'Nadia Al-Saadi',
      'role': 'Global CMO',
      'level': 2,
      'country': 'Global',
      'dept': 'Marketing',
      'avatar':
          'https://images.unsplash.com/photo-1551836022-deb4988cc6c0?w=80&h=80&fit=crop',
      'email': 'cmo@madar.com',
      'phone': '+964 770 000 0006',
      'status': 'active',
      'color': 0xFFBF360C,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_clo',
      'name': 'Hassan Al-Jubouri',
      'role': 'Global CLO',
      'level': 2,
      'country': 'Global',
      'dept': 'Legal',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop',
      'email': 'clo@madar.com',
      'phone': '+964 770 000 0007',
      'status': 'active',
      'color': 0xFF37474F,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cpo',
      'name': 'Reem Al-Mansouri',
      'role': 'Global CPO',
      'level': 2,
      'country': 'Global',
      'dept': 'Product',
      'avatar':
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=80&h=80&fit=crop',
      'email': 'cpo@madar.com',
      'phone': '+964 770 000 0008',
      'status': 'active',
      'color': 0xFF006064,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_chro',
      'name': 'Tariq Al-Obeidi',
      'role': 'Global CHRO',
      'level': 2,
      'country': 'Global',
      'dept': 'HR',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop',
      'email': 'chro@madar.com',
      'phone': '+964 770 000 0009',
      'status': 'active',
      'color': 0xFF880E4F,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cro',
      'name': 'Faisal Al-Douri',
      'role': 'Global Chief Risk Officer',
      'level': 2,
      'country': 'Global',
      'dept': 'Risk',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_14a5ca983-1763300171126.png',
      'email': 'cro@madar.com',
      'phone': '+964 770 000 0010',
      'status': 'active',
      'color': 0xFFB71C1C,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_cno',
      'name': 'Zainab Al-Hakim',
      'role': 'Global Chief Network Officer',
      'level': 2,
      'country': 'Global',
      'dept': 'Network',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_11f93ee64-1763296582119.png',
      'email': 'cno@madar.com',
      'phone': '+964 770 000 0011',
      'status': 'active',
      'color': 0xFF01579B,
      'parentId': 'global_ceo',
    },
    {
      'id': 'global_gov',
      'name': 'Mustafa Al-Samarrai',
      'role': 'Global Govt & Institutional Relations',
      'level': 2,
      'country': 'Global',
      'dept': 'Government',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_18e9dc4dd-1772257639814.png',
      'email': 'gov@madar.com',
      'phone': '+964 770 000 0012',
      'status': 'active',
      'color': 0xFF33691E,
      'parentId': 'global_ceo',
    },
    // ── Level 3: Country CEOs ──
    {
      'id': 'ceo_iraq',
      'name': 'Ali Al-Baghdadi',
      'role': 'CEO — Iraq',
      'level': 3,
      'country': 'Iraq',
      'dept': 'Executive',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1c96b2833-1786828391833.png',
      'email': 'ceo.iraq@madar.com',
      'phone': '+964 770 100 0001',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'global_ceo',
    },
    {
      'id': 'ceo_saudi',
      'name': 'Mohammed Al-Ghamdi',
      'role': 'CEO — Saudi Arabia',
      'level': 3,
      'country': 'Saudi Arabia',
      'dept': 'Executive',
      'avatar':
          'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=80&h=80&fit=crop',
      'email': 'ceo.sa@madar.com',
      'phone': '+966 50 100 0001',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'global_ceo',
    },
    {
      'id': 'ceo_uae',
      'name': 'Yousef Al-Mansoori',
      'role': 'CEO — UAE',
      'level': 3,
      'country': 'UAE',
      'dept': 'Executive',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_15059b443-1768200125164.png',
      'email': 'ceo.uae@madar.com',
      'phone': '+971 50 100 0001',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'global_ceo',
    },
    {
      'id': 'ceo_jordan',
      'name': 'Rami Al-Khalidi',
      'role': 'CEO — Jordan',
      'level': 3,
      'country': 'Jordan',
      'dept': 'Executive',
      'avatar':
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=80&h=80&fit=crop',
      'email': 'ceo.jo@madar.com',
      'phone': '+962 79 100 0001',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'global_ceo',
    },
    {
      'id': 'ceo_kuwait',
      'name': 'Bader Al-Sabah',
      'role': 'CEO — Kuwait',
      'level': 3,
      'country': 'Kuwait',
      'dept': 'Executive',
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1513023be-1786828392167.png',
      'email': 'ceo.kw@madar.com',
      'phone': '+965 99 100 0001',
      'status': 'active',
      'color': 0xFF1A237E,
      'parentId': 'global_ceo',
    },
    // ── Level 4: Country Executives (Iraq) ──
    {
      'id': 'coo_iraq',
      'name': 'Huda Al-Azzawi',
      'role': 'COO — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Operations',
      'avatar':
          'https://images.unsplash.com/photo-1598550874175-4d0ef436c909?w=80&h=80&fit=crop',
      'email': 'coo.iraq@madar.com',
      'phone': '+964 770 100 0002',
      'status': 'active',
      'color': 0xFF0D47A1,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'cfo_iraq',
      'name': 'Saad Al-Tikriti',
      'role': 'CFO — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Finance',
      'avatar':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=80&h=80&fit=crop',
      'email': 'cfo.iraq@madar.com',
      'phone': '+964 770 100 0003',
      'status': 'active',
      'color': 0xFF1B5E20,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'cto_iraq',
      'name': 'Bilal Al-Mosuli',
      'role': 'CTO — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Technology',
      'avatar':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=80&h=80&fit=crop',
      'email': 'cto.iraq@madar.com',
      'phone': '+964 770 100 0004',
      'status': 'active',
      'color': 0xFF4A148C,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'cmo_iraq',
      'name': 'Rana Al-Qaissi',
      'role': 'CMO — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Marketing',
      'avatar':
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=80&h=80&fit=crop',
      'email': 'cmo.iraq@madar.com',
      'phone': '+964 770 100 0005',
      'status': 'active',
      'color': 0xFFBF360C,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'legal_iraq',
      'name': 'Kareem Al-Fadhil',
      'role': 'Country Legal — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Legal',
      'avatar':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&h=80&fit=crop',
      'email': 'legal.iraq@madar.com',
      'phone': '+964 770 100 0006',
      'status': 'active',
      'color': 0xFF37474F,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'hr_iraq',
      'name': 'Dina Al-Rubaye',
      'role': 'Country HR — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'HR',
      'avatar':
          'https://images.unsplash.com/photo-1551836022-deb4988cc6c0?w=80&h=80&fit=crop',
      'email': 'hr.iraq@madar.com',
      'phone': '+964 770 100 0007',
      'status': 'active',
      'color': 0xFF880E4F,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'risk_iraq',
      'name': 'Waleed Al-Janabi',
      'role': 'Country Risk — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Risk',
      'avatar':
          'https://images.unsplash.com/photo-1556157382-97eda2d62296?w=80&h=80&fit=crop',
      'email': 'risk.iraq@madar.com',
      'phone': '+964 770 100 0008',
      'status': 'active',
      'color': 0xFFB71C1C,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'network_iraq',
      'name': 'Salam Al-Hamdani',
      'role': 'Country Network — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Network',
      'avatar':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop',
      'email': 'network.iraq@madar.com',
      'phone': '+964 770 100 0009',
      'status': 'active',
      'color': 0xFF01579B,
      'parentId': 'ceo_iraq',
    },
    {
      'id': 'gov_iraq',
      'name': 'Imad Al-Samarrai',
      'role': 'Government Relations — Iraq',
      'level': 4,
      'country': 'Iraq',
      'dept': 'Government',
      'avatar':
          'https://images.unsplash.com/photo-1463453091185-61582044d556?w=80&h=80&fit=crop',
      'email': 'gov.iraq@madar.com',
      'phone': '+964 770 100 0010',
      'status': 'active',
      'color': 0xFF33691E,
      'parentId': 'ceo_iraq',
    },
    // ── Level 5: Directors / Managers (Iraq Operations) ──
    {
      'id': 'ops_dir_iraq',
      'name': 'Noor Al-Kadhimi',
      'role': 'Operations Director — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Operations',
      'avatar':
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=80&h=80&fit=crop',
      'email': 'ops.dir.iraq@madar.com',
      'phone': '+964 770 200 0001',
      'status': 'active',
      'color': 0xFF0D47A1,
      'parentId': 'coo_iraq',
    },
    {
      'id': 'cx_mgr_iraq',
      'name': 'Layla Al-Zubaidi',
      'role': 'CX Manager — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Customer Experience',
      'avatar':
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=80&h=80&fit=crop',
      'email': 'cx.iraq@madar.com',
      'phone': '+964 770 200 0002',
      'status': 'active',
      'color': 0xFF006064,
      'parentId': 'coo_iraq',
    },
    {
      'id': 'tx_mgr_iraq',
      'name': 'Haider Al-Amiri',
      'role': 'Transaction Manager — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Transactions',
      'avatar':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&h=80&fit=crop',
      'email': 'tx.iraq@madar.com',
      'phone': '+964 770 200 0003',
      'status': 'active',
      'color': 0xFF00897B,
      'parentId': 'coo_iraq',
    },
    {
      'id': 'prop_mgr_iraq',
      'name': 'Suha Al-Bayati',
      'role': 'Property Manager — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Property',
      'avatar':
          'https://images.unsplash.com/photo-1594744803329-e58b31de8bf5?w=80&h=80&fit=crop',
      'email': 'prop.iraq@madar.com',
      'phone': '+964 770 200 0004',
      'status': 'active',
      'color': 0xFF7B1FA2,
      'parentId': 'coo_iraq',
    },
    {
      'id': 'finance_mgr_iraq',
      'name': 'Qasim Al-Rubaye',
      'role': 'Finance Manager — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Finance',
      'avatar':
          'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=80&h=80&fit=crop',
      'email': 'fin.mgr.iraq@madar.com',
      'phone': '+964 770 200 0005',
      'status': 'active',
      'color': 0xFF1B5E20,
      'parentId': 'cfo_iraq',
    },
    {
      'id': 'legal_mgr_iraq',
      'name': 'Zaid Al-Shammari',
      'role': 'Legal Manager — Iraq',
      'level': 5,
      'country': 'Iraq',
      'dept': 'Legal',
      'avatar':
          'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=80&h=80&fit=crop',
      'email': 'legal.mgr.iraq@madar.com',
      'phone': '+964 770 200 0006',
      'status': 'active',
      'color': 0xFF37474F,
      'parentId': 'legal_iraq',
    },
    // ── Level 6: Team Leaders / Specialists ──
    {
      'id': 'tl_cx_iraq',
      'name': 'Mariam Al-Khafaji',
      'role': 'CX Team Leader — Iraq',
      'level': 6,
      'country': 'Iraq',
      'dept': 'Customer Experience',
      'avatar':
          'https://images.unsplash.com/photo-1598550874175-4d0ef436c909?w=80&h=80&fit=crop',
      'email': 'tl.cx.iraq@madar.com',
      'phone': '+964 770 300 0001',
      'status': 'active',
      'color': 0xFF006064,
      'parentId': 'cx_mgr_iraq',
    },
    {
      'id': 'tl_tx_iraq',
      'name': 'Ammar Al-Saadi',
      'role': 'Transaction Team Leader — Iraq',
      'level': 6,
      'country': 'Iraq',
      'dept': 'Transactions',
      'avatar':
          'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=80&h=80&fit=crop',
      'email': 'tl.tx.iraq@madar.com',
      'phone': '+964 770 300 0002',
      'status': 'active',
      'color': 0xFF00897B,
      'parentId': 'tx_mgr_iraq',
    },
    {
      'id': 'sla_analyst_iraq',
      'name': 'Fatima Al-Hamdani',
      'role': 'SLA Analyst — Iraq',
      'level': 6,
      'country': 'Iraq',
      'dept': 'Customer Experience',
      'avatar':
          'https://images.unsplash.com/photo-1551836022-deb4988cc6c0?w=80&h=80&fit=crop',
      'email': 'sla.iraq@madar.com',
      'phone': '+964 770 300 0003',
      'status': 'active',
      'color': 0xFF006064,
      'parentId': 'cx_mgr_iraq',
    },
    {
      'id': 'risk_analyst_iraq',
      'name': 'Basim Al-Dulaimi',
      'role': 'Risk Analyst — Iraq',
      'level': 6,
      'country': 'Iraq',
      'dept': 'Risk',
      'avatar':
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=80&h=80&fit=crop',
      'email': 'risk.analyst.iraq@madar.com',
      'phone': '+964 770 300 0004',
      'status': 'active',
      'color': 0xFFB71C1C,
      'parentId': 'risk_iraq',
    },
    // ── Level 7: Operational Staff ──
    {
      'id': 'agent_1_iraq',
      'name': 'Yusuf Al-Jabouri',
      'role': 'Call Center Agent',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Support',
      'avatar':
          'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=80&h=80&fit=crop',
      'email': 'agent1.iraq@madar.com',
      'phone': '+964 770 400 0001',
      'status': 'active',
      'color': 0xFF1565C0,
      'parentId': 'tl_cx_iraq',
    },
    {
      'id': 'agent_2_iraq',
      'name': 'Nadia Al-Rubaye',
      'role': 'Transaction Coordinator',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Transactions',
      'avatar':
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=80&h=80&fit=crop',
      'email': 'agent2.iraq@madar.com',
      'phone': '+964 770 400 0002',
      'status': 'active',
      'color': 0xFF00897B,
      'parentId': 'tl_tx_iraq',
    },
    {
      'id': 'agent_3_iraq',
      'name': 'Khalil Al-Mosuli',
      'role': 'Property Info Specialist',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Operations',
      'avatar':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=80&h=80&fit=crop',
      'email': 'agent3.iraq@madar.com',
      'phone': '+964 770 400 0003',
      'status': 'active',
      'color': 0xFFF57C00,
      'parentId': 'ops_dir_iraq',
    },
    {
      'id': 'agent_4_iraq',
      'name': 'Hana Al-Bayati',
      'role': 'Photographer',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Media',
      'avatar':
          'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=80&h=80&fit=crop',
      'email': 'photo.iraq@madar.com',
      'phone': '+964 770 400 0004',
      'status': 'active',
      'color': 0xFF7B1FA2,
      'parentId': 'ops_dir_iraq',
    },
    {
      'id': 'lawyer_1_iraq',
      'name': 'Samer Al-Obeidi',
      'role': 'Lawyer / Legal Specialist',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Legal',
      'avatar':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=80&h=80&fit=crop',
      'email': 'lawyer1.iraq@madar.com',
      'phone': '+964 770 400 0005',
      'status': 'active',
      'color': 0xFF37474F,
      'parentId': 'legal_mgr_iraq',
    },
    {
      'id': 'bank_1_iraq',
      'name': 'Rasha Al-Tikriti',
      'role': 'Bank / Escrow Officer',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Finance',
      'avatar':
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=80&h=80&fit=crop',
      'email': 'bank1.iraq@madar.com',
      'phone': '+964 770 400 0006',
      'status': 'active',
      'color': 0xFF388E3C,
      'parentId': 'finance_mgr_iraq',
    },
    {
      'id': 'finance_1_iraq',
      'name': 'Luay Al-Kadhimi',
      'role': 'Finance Officer',
      'level': 7,
      'country': 'Iraq',
      'dept': 'Finance',
      'avatar':
          'https://images.unsplash.com/photo-1463453091185-61582044d556?w=80&h=80&fit=crop',
      'email': 'fin1.iraq@madar.com',
      'phone': '+964 770 400 0007',
      'status': 'active',
      'color': 0xFFF57C00,
      'parentId': 'finance_mgr_iraq',
    },
  ];

  List<Map<String, dynamic>> get _filteredData {
    return _orgData.where((e) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          e['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          e['role'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          e['dept'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesCountry =
          _selectedCountry == 'All' || e['country'] == _selectedCountry;
      return matchesSearch && matchesCountry;
    }).toList();
  }

  static const Map<int, String> _levelLabels = {
    0: 'Founder',
    1: 'Global CEO',
    2: 'Global C-Suite',
    3: 'Country CEOs',
    4: 'Country Executives',
    5: 'Directors & Managers',
    6: 'Team Leaders',
    7: 'Operational Staff',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0E1A),
                      Color(0xFF1A237E),
                      Color(0xFF0A0E1A),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Madar Organization',
                          style: GoogleFonts.dmSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_orgData.length} members · ${_countries.length - 1} countries',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFF0A0E1A),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF4FC3F7),
                  indicatorWeight: 2,
                  labelColor: const Color(0xFF4FC3F7),
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Hierarchy'),
                    Tab(text: 'Directory'),
                    Tab(text: 'Chart'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHierarchyTab(),
            _buildDirectoryTab(),
            _buildChartTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyTab() {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final e in _orgData) {
      final level = e['level'] as int;
      grouped.putIfAbsent(level, () => []).add(e);
    }
    final levels = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: levels.length,
      itemBuilder: (context, i) {
        final level = levels[i];
        final members = grouped[level]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withAlpha(153),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4FC3F7).withAlpha(77),
                      ),
                    ),
                    child: Text(
                      'L$level · ${_levelLabels[level] ?? ''}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4FC3F7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${members.length} member${members.length != 1 ? 's' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            ...members.map((m) => _buildMemberCard(m, level)),
            if (i < levels.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    Container(
                      width: 2,
                      height: 20,
                      color: const Color(0xFF4FC3F7).withAlpha(51),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, int level) {
    final color = Color(member['color'] as int);
    final indent = (level * 12.0).clamp(0.0, 60.0);

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 8),
      child: GestureDetector(
        onTap: () => _showMemberDetail(member),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(64), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(128), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    member['avatar'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: color.withAlpha(51),
                      child: Icon(Icons.person, color: color, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member['role'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      member['dept'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member['country'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryTab() {
    final filtered = _filteredData;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, role or department...',
                    hintStyle: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white38,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Country filter
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _countries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = _countries[i];
                    final selected = _selectedCountry == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCountry = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF4FC3F7)
                              : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF4FC3F7)
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          c,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? const Color(0xFF0A0E1A)
                                : Colors.white54,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _buildDirectoryCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryCard(Map<String, dynamic> member) {
    final color = Color(member['color'] as int);
    return GestureDetector(
      onTap: () => _showMemberDetail(member),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(128), width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  member['avatar'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withAlpha(51),
                    child: Icon(Icons.person, color: color, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member['role'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member['dept'] as String,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '· ${member['country']}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'L${member['level']}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab() {
    final deptCounts = <String, int>{};
    final countryCounts = <String, int>{};
    for (final e in _orgData) {
      deptCounts[e['dept'] as String] =
          (deptCounts[e['dept'] as String] ?? 0) + 1;
      if (e['country'] != 'Global') {
        countryCounts[e['country'] as String] =
            (countryCounts[e['country'] as String] ?? 0) + 1;
      }
    }

    final levelCounts = <int, int>{};
    for (final e in _orgData) {
      levelCounts[e['level'] as int] =
          (levelCounts[e['level'] as int] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Row(
          children: [
            _buildStatCard(
              'Total Staff',
              '${_orgData.length}',
              Icons.people,
              const Color(0xFF4FC3F7),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              'Countries',
              '5',
              Icons.public,
              const Color(0xFF81C784),
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              'Departments',
              '${deptCounts.length}',
              Icons.business,
              const Color(0xFFFFB74D),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Level distribution
        _buildSectionHeader('Staff by Level'),
        const SizedBox(height: 12),
        ...levelCounts.entries.map(
          (e) => _buildLevelBar(
            'L${e.key} · ${_levelLabels[e.key] ?? ''}',
            e.value,
            _orgData.length,
          ),
        ),
        const SizedBox(height: 20),
        // Country distribution
        _buildSectionHeader('Staff by Country'),
        const SizedBox(height: 12),
        ...countryCounts.entries.map(
          (e) => _buildCountryBar(e.key, e.value, _orgData.length),
        ),
        const SizedBox(height: 20),
        // Department distribution
        _buildSectionHeader('Staff by Department'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: deptCounts.entries
              .map((e) => _buildDeptChip(e.key, e.value))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLevelBar(String label, int count, int total) {
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
              ),
              Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4FC3F7),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryBar(String country, int count, int total) {
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                country,
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
              ),
              Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF81C784),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptChip(String dept, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '$dept ($count)',
        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white60),
      ),
    );
  }

  void _showMemberDetail(Map<String, dynamic> member) {
    final color = Color(member['color'] as int);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: ClipOval(
                child: Image.network(
                  member['avatar'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withAlpha(51),
                    child: Icon(Icons.person, color: color, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              member['name'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              member['role'] as String,
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDetailChip(member['dept'] as String, color),
                const SizedBox(width: 8),
                _buildDetailChip(member['country'] as String, Colors.white38),
                const SizedBox(width: 8),
                _buildDetailChip('Level ${member['level']}', Colors.white24),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactRow(Icons.email_outlined, member['email'] as String),
            const SizedBox(height: 8),
            _buildContactRow(Icons.phone_outlined, member['phone'] as String),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/employee-dashboard');
                    },
                    icon: const Icon(Icons.dashboard_outlined, size: 16),
                    label: Text(
                      'View Dashboard',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white60),
        ),
      ],
    );
  }
}
