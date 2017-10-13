window.AnimatorTrait = new Hfoo.Trait
    traitName: 'animator'
    before: ['sprite']
    after: ['collider']
    hasTrait: (entityDescription) ->
        return 'collider' of entityDescription and 'animator' of entityDescription and 'sprite' of entityDescription
    onLogic: (entity) ->
        if not entity.collider.grounded
            if entity.collider.velocity[1] < 0
                entity.sprite.setAnimation("fall")
            else if entity.collider.velocity[1] > 0
                entity.sprite.setAnimation("jump")
        else if entity.collider.velocity[0] isnt 0
            entity.sprite.setAnimation("walk")
        else
            entity.sprite.setAnimation("stand")