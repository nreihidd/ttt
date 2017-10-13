window.BonkHeadTrait = new Hfoo.Trait
    traitName: 'bonksHead'
    after: ['collider']
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'bonksHead' of entityDescription
    onLogic: (entity) ->
        if not entity.collider.grounded and entity.collider.velocity[1] > 0
            if entity.collider.contacts.top.length > 0
                entity.collider.velocity[1] = 0
                Hfoo.SoundManager.playSound("headBonk")
