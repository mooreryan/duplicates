TEST_D = test_files
TEST_FILE = $(TEST_D)/test.fa
TEST_OUTDIR = $(TEST_D)/out
ACTUAL_OUTPUT = $(TEST_OUTDIR)/test.no_duplicates.fa
PROG = remove_duplicates.rb

test:
	rm -r $(TEST_OUTDIR); ./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 1 && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_1.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 2 && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_2.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 3 && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_3.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 4 && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_4.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 5 && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_5.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 1 --low-memory && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_1.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 2 --low-memory && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_2.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 3 --low-memory && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_3.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 4 --low-memory && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_4.fa
	./$(PROG) -i $(TEST_D)/test.fa -o $(TEST_OUTDIR) -d 5 --low-memory && diff $(ACTUAL_OUTPUT) $(TEST_D)/expected.mode_5.fa
