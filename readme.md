# Tigml

I'll be mostly sticking to the script here. I took a stab at this a 
couple years ago but got stuck and ran low on time. I'm less focused
on getting a perfectly detailed implementaion and more on getting
something working that isn't a total mess.


## TODOs

[] Implement semant.ml
  [] Mock Translate module
  [] Write Env module
  [] Decide how to do error handling
    - I'm thinking that compiler internals should stick to poly variants
  [] Write translation functions without recursive declarations
    - How do I structure the code better than last time? 
    - I'm going to try separating typechecking from translation, that seemed
      gross last time
  [] Finish the translations
