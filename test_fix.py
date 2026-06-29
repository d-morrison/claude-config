import sys
sys.path.insert(0, 'scripts')
import importlib.util
spec = importlib.util.spec_from_file_location("slb", "scripts/semantic-line-breaks.py")
slb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(slb)

# Test case 1: multiple bare blockquote lines -> bq_text is blank -> sentences is empty
bq_lines = ['>', '>']
output = []
slb._flush_bq_prose(bq_lines, output)
assert output == ['>', '>'], f'FAIL test 1: got {output!r}'
print('Test 1 passed (multiple blank bq lines preserved)')

# Test case 2: single blank blockquote line
bq_lines = ['>']
output = []
slb._flush_bq_prose(bq_lines, output)
assert output == ['>'], f'FAIL test 2: got {output!r}'
print('Test 2 passed (single blank bq line preserved)')

# Test case 3: normal multi-sentence prose should still split
bq_lines = ['> First sentence. Second sentence.']
output = []
slb._flush_bq_prose(bq_lines, output)
assert len(output) == 2, f'FAIL test 3: expected 2 lines, got {output!r}'
print('Test 3 passed (prose still sentence-split)')

print('All tests passed.')
