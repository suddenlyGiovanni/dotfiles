function secrets --description 'sources secrets vars if presents'
    if test -e ~/.secrets
        source ~/.secrets
    end
end
