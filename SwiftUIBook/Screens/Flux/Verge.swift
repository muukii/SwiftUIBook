import Foundation

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public init(mutate: @escaping (inout State) -> Void) {
    self.mutate = mutate
  }
}

public struct _Action<State, Operations: OperationsType, ReturnType> where Operations.TargetState == State {
  
  let action: (DispatchContext<State, Operations>) -> ReturnType
  
  public init(action: @escaping (DispatchContext<State, Operations>) -> ReturnType) {
    self.action = action
  }
}

public protocol OperationsType {
  associatedtype TargetState
  
  typealias Mutation = _Mutation<TargetState>
  typealias Action<ReturnType> = _Action<TargetState, Self, ReturnType>
}

public final class DispatchContext<State, Operations: OperationsType> where Operations.TargetState == State {
  
  private let store: StoreBase<State, Operations>
  
  init(store: StoreBase<State, Operations>) {
    self.store = store
  }
  
  public func dispatch<ReturnType>(_ makeAction: (Operations) -> Operations.Action<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func dispatch(_ makeMutation: (Operations) -> Operations.Mutation) {
    store.dispatch(makeMutation)
  }
}

struct StorageSubscribeToken : Hashable {
  private let identifier = UUID().uuidString
}

final class Storage<Value> {
    
  private var subscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
  var value: Value {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicValue
  }
  
  private var nonatomicValue: Value
  
  private let lock = NSLock()
  
  init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  func update(_ update: (inout Value) throws -> Void) rethrows {
    lock.lock()
    do {
    try update(&nonatomicValue)
    } catch {
      lock.unlock()
      throw error
    }
    lock.unlock()
    notify(value: nonatomicValue)
  }
  
  
  @discardableResult
  func add(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock(); defer { lock.unlock() }
    let token = StorageSubscribeToken()
    subscribers[token] = subscriber
    return token
  }
  
  func remove(subscriber: StorageSubscribeToken) {
    lock.lock(); defer { lock.unlock() }
    subscribers.removeValue(forKey: subscriber)
  }
  
  @inline(__always)
  fileprivate func notify(value: Value) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.subscribers
    lock.unlock()
    subscribers.forEach { $0.value(value) }
  }
  
}

public struct StoreKey<State, Operations: OperationsType> : Hashable where Operations.TargetState == State {
  
  public let rawKey: String
  
  public init(additionalKey: String = "") {
//    let baseKey = "\(String(reflecting: State.self)):\(String(reflecting: Operations.self))"
    let baseKey = "\(String(reflecting: StoreKey<State, Operations>.self))"
    let key = baseKey + additionalKey
    self.rawKey = key
  }
  
  public init(from store: StoreBase<State, Operations>, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
  
  public init<Store: StoreType>(from store: Store, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
}

public protocol StoreType where Operations.TargetState == State {
  associatedtype State
  associatedtype Operations: OperationsType
  
  func dispatch<ReturnType>(_ makeAction: (Operations) -> Operations.Action<ReturnType>) -> ReturnType
  func dispatch(_ makeMutation: (Operations) -> Operations.Mutation)
}

public struct RegistrationToken {
  
  private let _unregister: () -> Void
  
  init(_ unregister: @escaping () -> Void) {
    self._unregister = unregister
  }
  
  public func unregister() {
    self._unregister()
  }
}

public class StoreBase<State, Operations: OperationsType>: StoreType where Operations.TargetState == State {
  
  public func dispatch<ReturnType>(_ makeAction: (Operations) -> _Action<Operations.TargetState, Operations, ReturnType>) -> ReturnType {
    fatalError()
  }
  
  public func dispatch(_ makeMutation: (Operations) -> _Mutation<Operations.TargetState>) {
    fatalError()
  }
    
  private var stores: [String : Any] = [:]
  private let lock = NSLock()
  
  private var registrationToken: RegistrationToken?
  
  func register<S, O: OperationsType>(store: StoreBase<S, O>, for key: String) -> RegistrationToken where O.TargetState == S {
    
    let key = StoreKey<S, O>.init(from: store).rawKey
    lock.lock()
    stores[key] = store
    
    let token = RegistrationToken { [weak self] in
      guard let self = self else { return }
      self.lock.lock()
      self.stores.removeValue(forKey: key)
      self.lock.unlock()
    }
    
    store.registrationToken = token
    lock.unlock()
    
    return token
  }
  
}

public final class Store<State, Operations: OperationsType>: StoreBase<State, Operations> where Operations.TargetState == State {
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  private let operations: Operations
  
  private let lock = NSLock()
  
  public init(
    state: State,
    operations: Operations
  ) {
    self.storage = .init(state)
    self.operations = operations
  }
  
  public override func dispatch<ReturnType>(_ makeAction: (Operations) -> Operations.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Operations>.init(store: self)
    let action = makeAction(operations)
    let result = action.action(context)
    return result
  }
  
  public override func dispatch(_ makeMutation: (Operations) -> Operations.Mutation) {
    let mutation = makeMutation(operations)
    storage.update { (state) in
      mutation.mutate(&state)
    }
  }
  
  public func makeScoped<ScopedState, ScopedOperations: OperationsType>(
    scope: WritableKeyPath<State, ScopedState>,
    operations: ScopedOperations
  ) -> ScopedStore<State, ScopedState, ScopedOperations> where ScopedOperations.TargetState == ScopedState {
    
    let scopedStore = ScopedStore<State, ScopedState, ScopedOperations>(
      store: self,
      scopeSelector: scope,
      operations: operations
    )
            
    return scopedStore
  }
  
}

public final class ScopedStore<SourceState, State, Operations: OperationsType>: StoreBase<State, Operations> where Operations.TargetState == State {
  
  public var state: State {
    storage.value[keyPath: scopeSelector]
  }
  
  private let operations: Operations
  let storage: Storage<SourceState>
  private let scopeSelector: WritableKeyPath<SourceState, State>
  
  init<SourceOperations: OperationsType>(
    store: Store<SourceState, SourceOperations>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    operations: Operations
  ) {
    
    self.storage = store.storage
    self.operations = operations
    self.scopeSelector = scopeSelector
    
  }
  
  public override func dispatch<ReturnType>(_ makeAction: (Operations) -> Operations.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Operations>.init(store: self)
    let action = makeAction(operations)
    let result = action.action(context)
    return result
  }
    
  public override func dispatch(_ makeMutation: (Operations) -> Operations.Mutation) {
    let mutation = makeMutation(operations)
    storage.update { (sourceState) in
      mutation.mutate(&sourceState[keyPath: scopeSelector])
    }
  }
}

#if canImport(Combine)
import Combine

private var _associated: Void?

extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_associated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { _ in
        associated.send()
      }
      
      return associated
    }
  }
}

extension Store: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

extension ScopedStore: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

#endif
