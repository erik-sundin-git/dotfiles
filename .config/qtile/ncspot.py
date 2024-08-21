from libqtile import base

class MyCustomWidget(base._InLoopPollText):

    def __init__(self, **config):
        super().__init__("", **config)
        self.add_defaults(base.PaddingMixin.defaults)
