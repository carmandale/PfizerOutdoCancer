#if canImport(MultipeerConnectivity) && canImport(ARKit)
import Foundation
import ARKit
import MultipeerConnectivity

public struct SharedRoomAnchor: Codable {
    public let identifier: UUID
    public let transform: simd_float4x4
}

public final class RoomShareService: NSObject {
    private let serviceType = "room-share"
    private let peerID = MCPeerID(displayName: UUID().uuidString)
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    public var receivedAnchorHandler: ((SharedRoomAnchor) -> Void)?

    public override init() {
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    public func broadcast(anchor: SharedRoomAnchor) {
        guard !session.connectedPeers.isEmpty else { return }
        if let data = try? JSONEncoder().encode(anchor) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}

extension RoomShareService: MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let anchor = try? JSONDecoder().decode(SharedRoomAnchor.self, from: data) {
            receivedAnchorHandler?(anchor)
        }
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}

    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}
#else
import Foundation
import simd

public struct SharedRoomAnchor: Codable {
    public let identifier: UUID
    public let transform: simd_float4x4
}

public final class RoomShareService {
    public init() {}
    public var receivedAnchorHandler: ((SharedRoomAnchor) -> Void)?
    public func broadcast(anchor: SharedRoomAnchor) {}
}
#endif
