//
//  Verge.swift
//  SwiftUIBook
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct _Mutation<State> {
  
  let mutate: (inout State) -> Void
  
  public init(mutate: @escaping (inout State) -> Void) {
    self.mutate = mutate
  }
}

public struct _Action<State, Mutations, Actions: ActionsType, ReturnType> where Mutations.State == State, Actions.State == State, Actions.Mutations == Mutations {
  
  let action: (DispatchContext<State, Mutations, Actions>) -> ReturnType
  
  public init(action: @escaping (DispatchContext<State, Mutations, Actions>) -> ReturnType) {
    self.action = action
  }
}

public protocol MutationsType {
  associatedtype State
  typealias Mutation = _Mutation<State>
  
}

public protocol ActionsType {
  associatedtype Mutations: MutationsType
  associatedtype State where Mutations.State == State
  typealias Action<ReturnType> = _Action<State, Mutations, Self, ReturnType>
}

public final class DispatchContext<State, Mutations, Actions: ActionsType> where Mutations.State == State, Actions.State == State, Actions.Mutations == Mutations {
  
  private let store: Store<State, Mutations, Actions>
  
  init(store: Store<State, Mutations, Actions>) {
    self.store = store
  }
  
  public func dispatch<ReturnType>(_ makeAction: (Actions) -> Actions.Action<ReturnType>) -> ReturnType {
    store.dispatch(makeAction)
  }
  
  public func commit(_ makeMutation: (Mutations) -> Mutations.Mutation) {
    store.commit(makeMutation)
  }
}

public class StoreBase {
  
  private var stores: [String : StoreBase] = [:]
  
  func register<Store: StoreBase>(store: Store, for key: String) {
    stores[key] = store
  }
}


public final class Store<State, Mutations, Actions: ActionsType>: StoreBase where
  Mutations.State == State,
  Actions.State == State,
  Actions.Mutations == Mutations
{
  
  public var state: State {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicState
  }
  
  private var nonatomicState: State
  
  private let mutations: Mutations
  private let actions: Actions
  
  private let lock = NSLock()
  
  public init(
    state: State,
    mutations: Mutations,
    actions: Actions
  ) {
    self.nonatomicState = state
    self.mutations = mutations
    self.actions = actions
  }
  
  public func dispatch<ReturnType>(_ makeAction: (Actions) -> Actions.Action<ReturnType>) -> ReturnType {
    let context = DispatchContext<State, Mutations, Actions>.init(store: self)
    let action = makeAction(actions)
    let result = action.action(context)
    return result
  }
  
  public func commit(_ makeMutation: (Mutations) -> Mutations.Mutation) {
    let mutation = makeMutation(mutations)
    lock.lock()
    mutation.mutate(&nonatomicState)
    lock.unlock()
  }
      
}

public final class ModularStore<State, Mutations, Actions>: StoreBase where
  Actions: ActionsType,
  Actions.State == State,
  Actions.Mutations == Mutations,
  Mutations.State == State
{
  
  private let mutations: Mutations
  private let actions: Actions
  private let lock = NSLock()
  
  init<SourceState, SourceMutations, SourceActions: ActionsType>(
    store: Store<SourceState, SourceMutations, SourceActions>,
    scopeSelector: WritableKeyPath<SourceState, State>,
    mutations: Mutations,
    actions: Actions
  ) where
    SourceMutations.State == SourceState,
    SourceActions.State == SourceState,
    SourceActions.Mutations == SourceMutations
  {
      
    self.mutations = mutations
    self.actions = actions
    
  }
  
//  public func dispatch<ReturnType>(_ makeAction: (Actions) -> Actions.Action<ReturnType>) -> ReturnType {
//    let context = DispatchContext<State, Mutations, Actions>.init(store: self)
//    let action = makeAction(actions)
//    let result = action.action(context)
//    return result
//  }
//  
//  public func commit(_ makeMutation: (Mutations) -> Mutations.Mutation) {
//    let mutation = makeMutation(mutations)
//    lock.lock()
//    mutation.mutate(&nonatomicState)
//    lock.unlock()
//  }
}
