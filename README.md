# Language Agents: NetLogo Simulation

## Overview

This project is a NetLogo simulation that models the evolution and interaction of languages across a border between two populations. Agents occupy patches on a grid, each with their own language vector, and interact with their neighbors to adapt and evolve their language over time. The simulation visualizes how language features spread, mix, and diverge in a spatially explicit environment.

<img width="627" alt="Screenshot 2025-06-20 at 15 42 20" src="https://github.com/user-attachments/assets/96976393-9f33-49a2-b433-669bd072c072" />

## Features
- **Two Populations:** Agents are initialized on either side of a central border, each with a distinct base language.
- **Language Vectors:** Each agent's language is represented as a vector of words, with each word being a vector of features.
- **Agent Interaction:** Agents can talk to neighbors, adapting their language based on a learning rate and the language of their peers.
- **Movement:** Agents can move to adjacent patches, with border difficulty affecting the probability of crossing the central border.
- **Variation Tracking:** The simulation tracks and plots the mean variation of words across the population, providing insight into language convergence or divergence.
- **Visualization:** Patch colors represent language features, and monitors/plots provide real-time feedback on language statistics.

## Demo
A demo presentation of the simulation is included in this repository as `demo.mov`.

## How to Run
1. **Install NetLogo:** Download and install [NetLogo](https://ccl.northwestern.edu/netlogo/).
2. **Open the Model:** Launch NetLogo and open the `language_agents.nlogo` file from this repository.
3. **Adjust Parameters:** Use the sliders to set parameters such as population density, intra-language variation, number of words, word length, border difficulty, and learning rate.
4. **Run the Simulation:** Click `setup` to initialize, then `go` to start the simulation. Observe the language evolution and variation plots.

## Parameters
- **population-density:** Probability of an agent spawning at a green field.
- **intra-language-variation:** Sets the amount of random variation in language features. Standard deviation of the zero-mean distribution from which
individual language variation is sampled. The variation is added to the default language vector of each population initially.
- **number-of-words:** Number of words in each agent's language vector – size of vocabulary.
- **word-length:** Number of features per word.
- **border-difficulty:** probability of agent not moving to a border patch once it decides to move there.
- **learning-rate:**  How much vocabulary changes after a conversation to be more similar to the partner’s.


