#!/usr/bin/env python
import sys, re
from subprocess import *
from pprint import pprint

def depends(target_name):
	try:
		output = check_output(r'ant -p -debug | grep -v "env\." | egrep -A 1 -B 0 "^\s*' \
			+ target_name \
			+ r'(\s|$)" | sed -n 2p | grep "^\s*depends on"', shell=True)
	except:
		return set()
	output = re.sub(r'^[^:]*:\s*', '', output).strip()
	output = re.sub(r'\s*(,)\s*', r'\1', output)
	return set(output.split(','))


def all_depends(main_target, resolve):
	targets = set()
	targets.add(main_target)

	to_process = set()
	to_process = depends(main_target)
	while len(to_process) > 0:
		current_target = to_process.pop()
		if resolve:
			current_targets = depends(current_target)
			if "resolve" in current_targets:
				return True
			for target in current_targets:
				to_process.add(target)
		else:
			for target in depends(current_target):
				to_process.add(target)
				targets.add(target)

	if resolve:
		return None
	else:
		return targets


def main():
	resolve = None
	if sys.argv[1] == '-r':
		resolve = True
		sys.argv = sys.argv[1:]
	targets = set()
	for target in sys.argv[1:]:
		if resolve:
			if all_depends(target, resolve):
				print('resolve')
				exit(0)
		else:
			for item in all_depends(target, resolve):
				if target != item:
					targets.add(item)
	if resolve:
		exit(0)
	else:
		for target in targets:
			print(target)


if __name__ == '__main__':
	main()
