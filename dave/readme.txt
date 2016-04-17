
IB_reconstructed/
	My implementation of Kramer 2008's fully connected IB model, from Jason's individual parts

basket_GABAB/
	My implementation of a basket cell with a GABA_B synapse

helper_dave/


~~~ kramer/ and kramer_IB/ ~~~

This is my played around with version of the original Kramer code from Jason.

kramer:
	This folder contains a few extra functions
		kramer/kramer/kramer_remove_all_but_IB.m

		This implements the full kramer model with the B, RS, and LTS cells cut
		out. This is a test to make sure that the model IB cells in the kramer model
                are the same as the kramer_IB model. IT appears that they are (see Google Doc
		presentation)

kramer_IB
	This used to contain the kramer_IB model, but now I've moved it to a separate repo.
	See: https://github.com/davestanley-cogrhythms/model-dnsim-kramer_IB






