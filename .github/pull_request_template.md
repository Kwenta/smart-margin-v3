## Pull Request Standards

### Commit Message Standards

1. Commit messages are short and in present tense.
2. 👷🏻‍♂️ prefix -> commits related to adjusting/adding contract logic
3. ✅ prefix -> commits related to testing
4. 📚 prefix -> commits related to documentation
5. ✨ prefix -> commits related to linting/formatting
6. ⛳️ prefix -> commits related to optimizations
7. 🗑️ prefix -> commits related to removing code
8. 🪲 prefix -> commits related to fixing bugs
9. 🚀 prefix -> commits related to deployments/scripts
10. ⚙️ prefix -> commits related to configuration files
11. 📸 prefix -> commits related to adding/updating gas-snapshots

### Pull Request Description Standards

Follow the below format for PR request descriptions:

```
{summary}

## Description
* Create
* Implement 
* Remove
* Test
* etc...

## Related issue(s)
Closes [Issue](https://github.com/Kwenta/repo/issues/{ID})

## Motivation and Context
Squashing bugs, adding features, etc...
```

## Checklist

Ensure you completed **all of the steps** below before submitting your pull request:

- [ ] Ran `forge fmt`?
- [ ] Ran `forge snapshot`?
- [ ] Ran `forge test`?

_Pull requests with an incomplete checklist will be thrown out._