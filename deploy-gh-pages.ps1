yarn install
ng build --bh /note-back/ --prod
git add docs
git commit -m "Update docs"

git add -A
git commit -m "add parent labels"
git push