import 'package:flutter/material.dart';

/// Global dil seçimi
final ValueNotifier<String> appLanguage = ValueNotifier<String>('tr');

class S {
  final String lang;
  const S(this.lang);

  static S of(String lang) => S(lang);

  bool get isTR => lang == 'tr';

  // Welcome Screen
  String get reservationForm      => isTR ? 'Rezervasyon Formu'          : 'Reservation Form';

  // Registration Screen
  String get firstName            => isTR ? 'Adınız'                     : 'First Name';
  String get lastName             => isTR ? 'Soyadınız'                  : 'Last Name';
  String get phoneNumber          => isTR ? 'Telefon Numaranız'          : 'Phone Number';
  String get selectEvent          => isTR ? 'Etkinlik Seçin'             : 'Select Event';
  String get createReservation    => isTR ? 'Randevu Oluştur'            : 'Create Reservation';
  String get registrationSuccess  => isTR ? 'Kayıt Başarılı!'            : 'Registration Successful!';
  String get welcomeMessage       => isTR ? 'Dans gecemize hoş geldiniz.': 'Welcome to our dance night.';
  String get ok                   => isTR ? 'Tamam'                      : 'OK';
  String get firstNameRequired    => isTR ? 'Lütfen adınızı girin'       : 'Please enter your first name';
  String get lastNameRequired     => isTR ? 'Lütfen soyadınızı girin'    : 'Please enter your last name';
  String get eventRequired        => isTR ? 'Lütfen bir etkinlik seçin'  : 'Please select an event';
  String get madeBy               => isTR ? 'Bu uygulama'                : 'This app was made by';
  String get madeByEnd            => isTR ? 'tarafından yapılmıştır'     : '';

  // Language button labels
  static String toggleLabel(String current) => current == 'tr' ? 'EN' : 'TR';
  static String toggleFull(String current)  => current == 'tr' ? 'English' : 'Türkçe';
}
