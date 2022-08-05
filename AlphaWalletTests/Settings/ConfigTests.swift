// Copyright SIX DAY LLC. All rights reserved.

import XCTest
@testable import AlphaWallet
import Combine

extension WalletConnectCoordinator {

    static func fake() -> WalletConnectCoordinator {
        let keystore = FakeEtherKeystore()
        var sessions = ServerDictionary<WalletSession>()
        let session = WalletSession.make()
        sessions[session.server] = session
        let sessionsSubject = CurrentValueSubject<ServerDictionary<WalletSession>, Never>(sessions)

        return WalletConnectCoordinator(keystore: keystore, navigationController: .init(), analyticsCoordinator: FakeAnalyticsService(), domainResolutionService: FakeDomainResolutionService(), config: .make(), sessionsSubject: sessionsSubject, assetDefinitionStore: AssetDefinitionStore())
    }
}

extension MultipleChainsTokenCollection {
    static func fake() -> MultipleChainsTokenCollection {
        let tokensDataStore = FakeTokensDataStore()
        let config: Config = .make()
        let actionsService = TokenActionsService()
        let tokenGroupIdentifier: TokenGroupIdentifierProtocol = FakeTokenGroupIdentifier()
        let tokensFilter = TokensFilter(assetDefinitionStore: .init(), tokenActionsService: actionsService, coinTickersFetcher: CoinGeckoTickersFetcher.make(), tokenGroupIdentifier: tokenGroupIdentifier)
        return MultipleChainsTokenCollection(tokensFilter: tokensFilter, tokensDataStore: tokensDataStore, config: config, coinTickersFetcher: CoinGeckoTickersFetcher.make())
    }
}

class ConfigTests: XCTestCase {

    //This is still used by Dapp browser
    func testChangeChainID() {
        let testDefaults = UserDefaults.test
        XCTAssertEqual(1, Config.getChainId(defaults: testDefaults))
        Config.setChainId(RPCServer.ropsten.chainID, defaults: testDefaults)
        XCTAssertEqual(RPCServer.ropsten.chainID, Config.getChainId(defaults: testDefaults))
    }

    func testSwitchLocale() {
        var sessions = ServerDictionary<WalletSession>()
        sessions[.main] = WalletSession.make()

        let config: Config = .make()
        Config.setLocale(AppLocale.english)
        let tokenActionsService = FakeSwapTokenService()

        let coordinator_1 = TokensCoordinator(
            navigationController: FakeNavigationController(),
            sessions: sessions,
            keystore: FakeEtherKeystore(),
            config: config,
            assetDefinitionStore: AssetDefinitionStore(),
            eventsDataStore: FakeEventsDataStore(),
            promptBackupCoordinator: PromptBackupCoordinator(keystore: FakeEtherKeystore(), wallet: .make(), config: config, analyticsCoordinator: FakeAnalyticsService()),
            analyticsCoordinator: FakeAnalyticsService(),
            openSea: OpenSea(analyticsCoordinator: FakeAnalyticsService(), queue: .global()),
            tokenActionsService: tokenActionsService,
            walletConnectCoordinator: .fake(),
            coinTickersFetcher: CoinGeckoTickersFetcher.make(),
            activitiesService: FakeActivitiesService(),
            walletBalanceService: FakeMultiWalletBalanceService(),
            tokenCollection: MultipleChainsTokenCollection.fake(),
            importToken: FakeImportToken(),
            blockiesGenerator: .make(),
            domainResolutionService: FakeDomainResolutionService()
        )

        coordinator_1.start()
        coordinator_1.tokensViewController.viewWillAppear(false)
        XCTAssertEqual(coordinator_1.tokensViewController.title, "Wallet")

        Config.setLocale(AppLocale.simplifiedChinese)

        let coordinator_2 = TokensCoordinator(
            navigationController: FakeNavigationController(),
            sessions: sessions,
            keystore: FakeEtherKeystore(),
            config: config,
            assetDefinitionStore: AssetDefinitionStore(),
            eventsDataStore: FakeEventsDataStore(),
            promptBackupCoordinator: PromptBackupCoordinator(keystore: FakeEtherKeystore(), wallet: .make(), config: config, analyticsCoordinator: FakeAnalyticsService()),
            analyticsCoordinator: FakeAnalyticsService(),
            openSea: OpenSea(analyticsCoordinator: FakeAnalyticsService(), queue: .global()),
            tokenActionsService: tokenActionsService,
            walletConnectCoordinator: .fake(),
            coinTickersFetcher: CoinGeckoTickersFetcher.make(),
            activitiesService: FakeActivitiesService(),
            walletBalanceService: FakeMultiWalletBalanceService(),
            tokenCollection: MultipleChainsTokenCollection.fake(),
            importToken: FakeImportToken(),
            blockiesGenerator: .make(),
            domainResolutionService: FakeDomainResolutionService()
        )

        coordinator_2.start()
        coordinator_2.tokensViewController.viewWillAppear(false)
        XCTAssertEqual(coordinator_2.tokensViewController.title, "我的钱包")

        //Must change this back to system, otherwise other tests will break either immediately or the next run
        Config.setLocale(AppLocale.system)
    }

    func testMakeSureDevelopmentFlagsAreAllFalse() {
        let mirror = Mirror(reflecting: Config.Development())
        for child in mirror.children {
            if let value = child.value as? Bool {
                XCTAssertFalse(value, "Property: \(String(describing: child.label)) should be `false`")
            } else {
                XCTFail("Property: \(String(describing: child.label)) should be `bool`")
            }
        }
    }
}
