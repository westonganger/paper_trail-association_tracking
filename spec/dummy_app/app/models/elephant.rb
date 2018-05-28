# frozen_string_literal: true

class Elephant < Animal
end

# Nice! We used to have `paper_trail.disable` inside the class, which was really
# misleading because it looked like a permanent, global setting. It's so much
# more obvious now that we are disabling the model for this request only. Of
# course, we run the PT unit tests in a single thread, and I think this setting
# will affect multiple unit tests, but in a normal application, this new API is
# a huge improvement.

PaperTrail.request.disable_model(Elephant)
