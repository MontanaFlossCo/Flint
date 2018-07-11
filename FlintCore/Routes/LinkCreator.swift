//
//  URLGenerator.swift
//  FlintCore
//
//  Created by Marc Palmer on 16/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A class that is used to create URLs that will invoke App actions.
///
/// Flint Routes support multiple custom app URL schemes and multiple associated domains for deep linking.
///
/// A LinkCreator will only create links for one app scheme or domain - typically apps do not need to generate different
/// kinds of URLs for the same app, but you may need to handle multiple legacy URLs or domains.
///
/// As such, Flint will create a default link creator for the first App URL scheme and Associated Domain that you define
/// in your Info.plist (for app URLs) and the domain you pass when calling `Flint.quickSetup`.
///
/// This will be used for the automatic link creation for Activities and other system integrations. You can
/// change this behaviour by creating a new `LinkCreator` for the scheme and domain you prefer, and assign it to
/// `Flink.linkCreator`.
///
/// You can create your own instances to produce links with specific schemes and domains. Links can only be created
/// for actions that have routes defined in your Feature's `urlMappings`.
public class LinkCreator {
    public let defaultScheme: String?
    public let defaultDomain: String?
    
    /// Instantiate a link creator for the given scheme and domain.
    /// Note that you cannot use just any scheme or domain. They must be correctly configured in your app's
    /// `Info.plist` and Associated Domains entitlements.
    public init(scheme: String?, domain: String?) {
        self.defaultScheme = scheme
        self.defaultDomain = domain
    }

    /// Create an app custom URL scheme link to the specified static feature action, passing the input provided.
    ///
    /// - note: the input must conform to `QueryParametersEncodable`, and anything output from that protocol will be user-visible in the URL generated.
    public func appLink<FeatureType, ActionType>(to actionBinding: StaticActionBinding<FeatureType, ActionType>, with input: ActionType.InputType?) -> URL where ActionType.InputType: RouteParametersEncodable {
        guard let scheme = defaultScheme else {
            flintUsageError("No app URL scheme available")
        }
        guard let mappings = ActionURLMappings.instance.mappings(for: actionBinding.feature, action: actionBinding.action.name) else {
            flintUsageError("No URL mapping exists for: \(actionBinding)")
        }
        let matchedMapping = mappings.first { $0.scope.isApp }
        guard let mapping = matchedMapping else {
            flintUsageError("No app URL mapping found for: \(actionBinding)")
        }
        return build(mapping: mapping, defaultPrefix: scheme, with: input)
    }
    
    /// Create an app custom URL scheme link to the specified conditional feature action, passing the input provided.
    ///
    /// - note: the input must conform to `QueryParametersEncodable`, and anything output from that protocol will be user-visible in the URL generated.
    public func appLink<FeatureType, ActionType>(to actionBinding: ConditionalActionBinding<FeatureType, ActionType>, with input: ActionType.InputType?) -> URL where ActionType.InputType: RouteParametersEncodable {
        guard let scheme = defaultScheme else {
            flintUsageError("No app URL scheme available")
        }
        guard let mappings = ActionURLMappings.instance.mappings(for: actionBinding.feature, action: actionBinding.action.name) else {
            flintUsageError("No URL mapping exists for: \(actionBinding)")
        }
        let matchedMapping = mappings.first { $0.scope.isApp }
        guard let mapping = matchedMapping else {
            flintUsageError("No app URL mapping found for: \(actionBinding)")
        }
        return build(mapping: mapping, defaultPrefix: scheme, with: input)
    }
    
    /// Create a universal/domain URL linking to the specified static feature action, passing the input provided.
    ///
    /// - note: the input must conform to `QueryParametersEncodable`, and anything output from that protocol will be user-visible in the URL generated.
    public func universalLink<FeatureType, ActionType>(to actionBinding: StaticActionBinding<FeatureType, ActionType>, with input: ActionType.InputType?) -> URL where ActionType.InputType: RouteParametersEncodable {
        guard let domain = defaultDomain else {
            flintUsageError("No associated domain available")
        }
        guard let mappings = ActionURLMappings.instance.mappings(for: actionBinding.feature, action: actionBinding.action.name) else {
            flintUsageError("No URL mapping exists for: \(actionBinding)")
        }
        let matchedMapping = mappings.first { $0.scope.isUniversal }
        guard let mapping = matchedMapping else {
            flintUsageError("No app URL mapping found for: \(actionBinding)")
        }
        return build(mapping: mapping, defaultPrefix: domain, with: input)
    }
    
    /// Create a universal/domain URL linking to the specified conditional feature action, passing the input provided.
    ///
    /// - note: the input must conform to `QueryParametersEncodable`, and anything output from that protocol will be user-visible in the URL generated.
    public func universalLink<FeatureType, ActionType>(to actionBinding: ConditionalActionBinding<FeatureType, ActionType>, with input: ActionType.InputType?) -> URL where ActionType.InputType: RouteParametersEncodable {
        guard let domain = defaultDomain else {
            flintUsageError("No associated domain available")
        }
        guard let mappings = ActionURLMappings.instance.mappings(for: actionBinding.feature, action: actionBinding.action.name) else {
            flintUsageError("No URL mapping exists for: \(actionBinding)")
        }
        let matchedMapping = mappings.first { $0.scope.isUniversal }
        guard let mapping = matchedMapping else {
            flintUsageError("No app URL mapping found for: \(actionBinding)")
        }
        return build(mapping: mapping, defaultPrefix: domain, with: input)
    }

    // MARK: Internals
    
    /// This is an internal unsafe function that takes pre-encoded query params for state, so it must only be called with
    /// state that has already been encoded and of the InputType appropriate for T. This is because we cannot
    /// constrain on `T.InputType: QueryParametersEncodable` at a call site that is only constrained on `T: Action`.
    func appLink<FeatureType, ActionType>(to actionBinding: StaticActionBinding<FeatureType, ActionType>, with encodableState: RouteParametersEncodable?) -> URL {
        guard let scheme = defaultScheme else {
            flintUsageError("No app URL scheme available")
        }
        guard let mappings = ActionURLMappings.instance.mappings(for: actionBinding.feature, action: actionBinding.action.name) else {
            flintUsageError("No URL mapping exists for: \(actionBinding)")
        }
        let matchedMapping = mappings.first { $0.scope.isApp }
        guard let mapping = matchedMapping else {
            flintUsageError("No app URL mapping found for: \(actionBinding)")
        }
        let encodedState = encodableState?.encodeAsRouteParameters(for: mapping)
        return build(mapping: mapping, defaultPrefix: scheme, with: encodedState)
    }
    
    private func build<T>(mapping: URLMapping, defaultPrefix: String, with state: T?) -> URL where T: RouteParametersEncodable {
        let params = state?.encodeAsRouteParameters(for: mapping)
        return build(mapping: mapping, defaultPrefix: defaultPrefix, with: params)
    }

    private func build(mapping: URLMapping, defaultPrefix: String, with encodedState: RouteParameters?) -> URL {
        return mapping.buildLink(with: encodedState, defaultPrefix: defaultPrefix)
    }

}
