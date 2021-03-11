//
//  StringResource.swift
//  R.swift.Library
//
//  Created by Tom Lokhorst on 2016-04-23.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation

public protocol StringResourceType {

  /// Key for the string
  var key: String { get }

  /// File in containing the string
  var tableName: String { get }

  /// Bundle this string is in
  var bundle: Bundle { get }

  /// Locales of the a localizable string
  var locales: [String] { get }

  /// The value to return if key is nil or if a localized string for key can’t be found in the table.
  var value: String? { get }

  /// Comment directly before and/or after the string, if any
  var comment: String? { get }
}

public struct StringResource: StringResourceType {

  /// Key for the string
  public let key: String

  /// File in containing the string
  public let tableName: String

  /// Bundle this string is in
  public let bundle: Bundle

  /// Locales of the a localizable string
  public let locales: [String]

  /// The value to return if key is nil or if a localized string for key can’t be found in the table.
  public let value: String?

  /// Comment directly before and/or after the string, if any
  public let comment: String?

  public init(key: String, tableName: String, bundle: Bundle, locales: [String], value: String?, comment: String?) {
    self.key = key
    self.tableName = tableName
    self.bundle = bundle
    self.locales = locales
    self.value = value
    self.comment = comment
  }

  public func callAsFunction(preferredLanguages: [String]? = nil) -> String {
    guard let preferredLanguages = preferredLanguages else {
      return NSLocalizedString(key, bundle: bundle, value: value ?? "", comment: comment ?? "")
    }

    guard let (_, bundle) = localeBundle(tableName: tableName, preferredLanguages: preferredLanguages) else {
      return value ?? ""
    }

    return NSLocalizedString(key, bundle: bundle, value: "", comment: comment ?? "")
  }

  private var applicationLocale: Locale {
    bundle.preferredLocalizations.first.flatMap { Locale(identifier: $0) } ?? Locale.current
  }

  private func localeBundle(tableName: String, preferredLanguages: [String]) -> (Foundation.Locale, Foundation.Bundle)? {
    // Filter preferredLanguages to localizations, use first locale
    var languages = preferredLanguages
      .map { Locale(identifier: $0) }
      .prefix(1)
      .flatMap { locale -> [String] in
        if bundle.localizations.contains(locale.identifier) {
          if let language = locale.languageCode, bundle.localizations.contains(language) {
            return [locale.identifier, language]
          } else {
            return [locale.identifier]
          }
        } else if let language = locale.languageCode, bundle.localizations.contains(language) {
          return [language]
        } else {
          return []
        }
      }

    // If there's no languages, use development language as backstop
    if languages.isEmpty {
      if let developmentLocalization = bundle.developmentLocalization {
        languages = [developmentLocalization]
      }
    } else {
      // Insert Base as second item (between locale identifier and languageCode)
      languages.insert("Base", at: 1)

      // Add development language as backstop
      if let developmentLocalization = bundle.developmentLocalization {
        languages.append(developmentLocalization)
      }
    }

    // Find first language for which table exists
    // Note: key might not exist in chosen language (in that case, key will be shown)
    for language in languages {
      if let lproj = bundle.url(forResource: language, withExtension: "lproj"),
         let lbundle = Bundle(url: lproj)
      {
        let strings = lbundle.url(forResource: tableName, withExtension: "strings")
        let stringsdict = lbundle.url(forResource: tableName, withExtension: "stringsdict")

        if strings != nil || stringsdict != nil {
          return (Locale(identifier: language), lbundle)
        }
      }
    }

    // If table is available in main bundle, don't look for localized resources
    let strings = bundle.url(forResource: tableName, withExtension: "strings", subdirectory: nil, localization: nil)
    let stringsdict = bundle.url(forResource: tableName, withExtension: "stringsdict", subdirectory: nil, localization: nil)

    if strings != nil || stringsdict != nil {
      return (applicationLocale, bundle)
    }

    // If table is not found for requested languages, key will be shown
    return nil
  }
}
